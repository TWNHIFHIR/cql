//乳癌_Eribulin給付規定
library BCEribulinRule1 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

include BCCodeConcept version '1.0.0' called CodeConcept

include BCReusable version '1.0.0' called Reusable

context Patient


//============================================
// 主要規定一：初次使用條件
//============================================

/*規則1*/

define "ICD代碼檢核_布林值": Reusable."ICD-10使用C50"

define "醫令類別為1_布林值":Reusable."醫令類別為1"

//條件1:治療轉移性乳癌患者
//條件1-1
define "規則1-1-1=6個月內影像報告":
  Reusable."HasRecentImageReport"("本次申請起始日期", 180)


//條件1-2
define "規則1-1-2=癌症分期分數或結果為M≠0":
  Reusable."癌症分期分數或結果為M≠0"


//條件1-3
define "規則1-1-3=Eribulin申請":
  exists (        
    [MedicationRequest] MRPlan
    where MRPlan.intent = 'plan'
      and exists (
        MRPlan.medication.coding Cdg
        where Cdg in CodeConcept.NHIMedication
          and Cdg.code in CodeConcept.L01XX41
      )
  )

define "規則1-1=治療轉移性乳癌患者":
"ICD代碼檢核_布林值" 
and "醫令類別為1_布林值"
and "規則1-1-2=癌症分期分數或結果為M≠0"
and "規則1-1-3=Eribulin申請"
or "規則1-1-1=6個月內影像報告"  


//條件2:先前曾接受過anthracycline和taxane兩種針對轉移性乳癌之化學治療輔助性治療
define "規則1-2=先前曾接受過anthracycline和taxane兩種針對轉移性乳癌之化學治療輔助性治療":
  // 先前使用過 anthracycline (L01DB01 或 L01DB03)
  Reusable."HasPriorMedicationUse"(CodeConcept.L01XX41, CodeConcept.L01DB01)
  or Reusable."HasPriorMedicationUse"(CodeConcept.L01XX41, CodeConcept.L01DB03)
  and (
    // 先前使用過 taxane (L01CD01 或 L01CD02)
    Reusable."HasPriorMedicationUse"(CodeConcept.L01XX41, CodeConcept.L01CD01)
    or Reusable."HasPriorMedicationUse"(CodeConcept.L01XX41, CodeConcept.L01CD02)
  )
  and Reusable."醫令類別為1"


// 主要規定一
define "主要規定一":
"規則1-1=治療轉移性乳癌患者" 
and "規則1-2=先前曾接受過anthracycline和taxane兩種針對轉移性乳癌之化學治療輔助性治療"


//============================================
// 主要規定二：續用條件－治療持續給付
//============================================

//條件1:每3個療程需進行療效評估

// 本次申請紀錄（以最新一筆申請作為本次申請）
define "本次申請紀錄":
  Reusable."LatestMedicationPlan"(CodeConcept.L01XX41)

define "本次申請起始日期":
  Reusable."GetStartTime"("本次申請紀錄")

// 前次申請紀錄（本次申請之前最近一次的申請）
define "前次申請紀錄":
  Reusable."LatestMedicationPlanBefore"(CodeConcept.L01XX41, "本次申請起始日期")

// 每3個療程間隔的邏輯
define "規則1-1=每3個療程需進行療效評估":
  Reusable."醫令類別為1" 
  and Reusable."續用註記為2"
  and "前次申請紀錄" is not null
  and "本次申請紀錄" is not null
  and (
    // 計算前次申請結束日期到本次申請開始日期的天數差異
    difference in days between
      FHIRHelpers.ToDateTime(("前次申請紀錄".dosageInstruction[0].timing.repeat.bounds as Period).end)
      and FHIRHelpers.ToDateTime(("本次申請紀錄".dosageInstruction[0].timing.repeat.bounds as Period).start)
  ) <= 63


//條件2:疾病有惡化情形須停止使用

// 取得前次治療紀錄（最近一次已完成的治療）
define "前次治療紀錄":
  Reusable."LatestCompletedMedicationOrderBefore"(CodeConcept.L01XX41, "本次申請起始日期")

// 前次用藥開始日期
define "前次用藥開始日期":
  Reusable."GetStartTime"("前次治療紀錄")

// 規則1-2: 疾病有惡化情形須停止使用(續用須檢附前次治療後影像學報告)
define "規則1-2=疾病有惡化情形須停止使用":
  Reusable."HasImageReportBetweenPreviousTreatmentAndCurrentApply"(CodeConcept.L01XX41)

// 主要規定二
define "主要規定二：續用條件":
Reusable."續用註記為2"
and Reusable."醫令類別為1"
and "本次申請紀錄" is not null
and "規則1-1=每3個療程需進行療效評估"
and "規則1-2=疾病有惡化情形須停止使用"


//============================================
// 主要規定三：藥品使用規則
//============================================

//條件1:沒有使用ixabepilone (申請期間不能使用,但過去可以用過)
define "主要規定三：沒有使用ixabepilone":
  // 申請期間不能與 ixabepilone 時間重疊
  not Reusable."HasConcurrentMedicationOrder"(CodeConcept.L01XX41, CodeConcept.L01DC04)


//============================================
// 列出「符合」項目判斷式
//============================================

define function "符合項目"():
  // 主要規定一：初次使用條件
  (if Reusable."初次申請" and (
    "ICD代碼檢核_布林值" or 
    "醫令類別為1_布林值" or 
    "規則1-1-1=6個月內影像報告" or 
    "規則1-1-2=癌症分期分數或結果為M≠0" or 
    "規則1-1-3=Eribulin申請" or 
    "規則1-2=先前曾接受過anthracycline和taxane兩種針對轉移性乳癌之化學治療輔助性治療"
  )
    then '<主要規定一：初次使用條件>\n' +
         (if "ICD代碼檢核_布林值" 
           then '● ICD代碼檢核：主要疾病之ICD代碼使用C50\n' else '') +
         (if "醫令類別為1_布林值" 
           then '● 醫令類別檢核：醫令類別為1(癌症治療)\n' else '') +
         (if "規則1-1-1=6個月內影像報告" 
           then '● 規則1-1-1：6個月內影像報告\n' else '') +
         (if "規則1-1-2=癌症分期分數或結果為M≠0" 
           then '● 規則1-1-2：癌症分期分數或結果為M≠0(轉移性)\n' else '') +
         (if "規則1-1-3=Eribulin申請" 
           then '● 規則1-1-3：Eribulin申請\n' else '') +
         (if "規則1-2=先前曾接受過anthracycline和taxane兩種針對轉移性乳癌之化學治療輔助性治療" 
           then '● 規則1-2：已接受anthracycline和taxane化學治療\n' else '') +
         '\n'
    else '') +
  
  // 主要規定二：續用條件
  (if Reusable."續用申請" and (
    "規則1-1=每3個療程需進行療效評估" or 
    "規則1-2=疾病有惡化情形須停止使用"
  )
    then '<主要規定二：續用條件－治療持續給付>\n' +
         (if "規則1-1=每3個療程需進行療效評估" 
           then '● 續用規則1-1：於3個療程(63天)內再次申請並檢附療效評估資料\n' else '') +
         (if "規則1-2=疾病有惡化情形須停止使用" 
           then '● 續用規則1-2：已檢附前次治療後影像學報告，確認無惡化\n' else '') +
         '\n'
    else '') +
  
  // 主要規定三：藥品使用規則
  (if "主要規定三：沒有使用ixabepilone"
    then '<主要規定三：藥品使用規則>\n' +
         '● 規則3-1：未併用ixabepilone\n'
    else '')

//============================================
// 列出「不符合」項目判斷式 - 代碼或條件不符
//============================================

define function "不符合項目_代碼或條件不符"():
  // 主要規定一：初次使用條件 - 代碼條件不符
  (if Reusable."初次申請" and (
    not "ICD代碼檢核_布林值" or 
    not "醫令類別為1_布林值"
  )
    then '<主要規定一：初次使用條件>\n' +
         (if not "ICD代碼檢核_布林值" 
           then '▲ ICD代碼檢核：主要疾病之ICD代碼未使用C50\n' else '') +
         (if not "醫令類別為1_布林值" 
           then '▲ 醫令類別檢核：醫令類別非1\n' else '') +
         '\n'
    else '') +
  
  // 主要規定三：藥品使用規則 - 代碼條件不符
  (if not "主要規定三：沒有使用ixabepilone"
    then '<主要規定三：藥品使用規則>\n' +
         '▲ 規則3-1：申請期間併用ixabepilone(不可併用)\n'
    else '')

//============================================
// 列出「不符合」項目判斷式 - 必要資料未填寫
//============================================

define function "不符合項目_必要資料未填寫"():
  // 主要規定一：初次使用條件 - 必要資料未填寫
  (if Reusable."初次申請" and (
    not "規則1-1-1=6個月內影像報告" or 
    not "規則1-1-2=癌症分期分數或結果為M≠0" or 
    not "規則1-1-3=Eribulin申請" or 
    not "規則1-2=先前曾接受過anthracycline和taxane兩種針對轉移性乳癌之化學治療輔助性治療"
  )
    then '<主要規定一：初次使用條件>\n' +
         (if not "規則1-1-1=6個月內影像報告" 
           then '▲ 規則1-1-1：未提供6個月內影像報告\n' else '') +
         (if not "規則1-1-2=癌症分期分數或結果為M≠0" 
           then '▲ 規則1-1-2：未提供癌症分期資料或非轉移性(M=0)\n' else '') +
         (if not "規則1-1-3=Eribulin申請" 
           then '▲ 規則1-1-3：未提供Eribulin申請資料\n' else '') +
         (if not "規則1-2=先前曾接受過anthracycline和taxane兩種針對轉移性乳癌之化學治療輔助性治療" 
           then '▲ 規則1-2：未提供anthracycline和taxane化學治療紀錄\n' else '') +
         '\n'
    else '') +
  
  // 主要規定二：續用條件 - 必要資料未填寫
  (if Reusable."續用申請" and (
    not "規則1-1=每3個療程需進行療效評估" or 
    not "規則1-2=疾病有惡化情形須停止使用"
  )
    then '<主要規定二：續用條件－治療持續給付>\n' +
         (if not "規則1-1=每3個療程需進行療效評估" 
           then '▲ 續用規則1-1：超過3個療程(63天)未再次申請或未檢附療效評估資料\n' else '') +
         (if not "規則1-2=疾病有惡化情形須停止使用" 
           then '▲ 續用規則1-2：未提供前次治療後影像學報告或顯示疾病惡化\n' else '') +
         '\n'
    else '')

//============================================
// 審核結果
//============================================

define "乳癌Eribulin申請結果_布林":
  case
    when Reusable."初次申請" then (
      "主要規定一" and
      "主要規定三：沒有使用ixabepilone"
    )
    when Reusable."續用申請" then (
      "主要規定二：續用條件" and
      "主要規定三：沒有使用ixabepilone"
    )
    else false
  end

define "乳癌Eribulin申請之CQL檢核結果":
  if (
    Reusable."初次申請" and 
    "主要規定一" and
    "主要規定三：沒有使用ixabepilone"
  )
  then '✓通過：初次使用－乳癌Eribulin用藥申請'

  else if (
    Reusable."續用申請" and
    "主要規定二：續用條件" and
    "主要規定三：沒有使用ixabepilone"
  )
  then '✓通過：續用－乳癌 Eribulin 用藥申請'
  else if Reusable."初次申請"
  then '✖不通過：初次使用－乳癌 Eribulin 用藥申請'
  else if Reusable."續用申請"
  then '✖不通過：續用－乳癌 Eribulin 用藥申請'
  else '✖不通過：無法判定申請類型－乳癌 Eribulin 用藥申請'

//============================================
// 報告總結
//============================================

define "報告總結":
  '\n=== 乳癌之Eribulin申請審核報告 ===\n' +
  '\n【申請類型】' + Reusable."申請類型" + '\n' +
  '\n【●符合項目】\n' +
  (if "符合項目"() = '' then '無\n' else "符合項目"()) +
  '\n【▲不符合項目 - 代碼或條件不符】\n' +
  (if "不符合項目_代碼或條件不符"() = '' then '無\n' else "不符合項目_代碼或條件不符"()) +
  '\n【▲不符合項目 - 必要資料未填寫】\n' +
  (if "不符合項目_必要資料未填寫"() = '' then '無\n' else "不符合項目_必要資料未填寫"()) +
  '\n【申請結果】\n' +
  "乳癌Eribulin申請之CQL檢核結果" +
  '\n===============================================\n'
