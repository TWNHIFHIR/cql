//乳癌_Everolimus給付規定
library BCEverolimusRule1 version '1.0.0'

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

//條件1:轉移性乳癌
//條件1-1
define "規則1-1-1=3個月內影像報告":
  Reusable."HasRecentImageReport"("本次申請起始日期", 90)



//條件1-3
define "規則1-1-3=癌症分期分數或結果為M≠0":
  Reusable."癌症分期分數或結果為M≠0"


//條件1-4(檢查報告)
define "規則1-1-4=3個月內有檢查報告":
  Reusable."HasRecentMolecularReport"("本次申請起始日期", 90)

//條件1-5
define "規則1-1-5=Everolimus申請":
  exists (        
    [MedicationRequest] MRPlan
    where MRPlan.intent = 'plan'
      and exists (
        MRPlan.medication.coding Cdg
        where Cdg in CodeConcept.NHIMedication
          and Cdg.code in CodeConcept.Everolimus
      )
  )

define "規則1-1=轉移性乳癌":
"ICD代碼檢核_布林值" and "醫令類別為1_布林值"
and "規則1-1-1=3個月內影像報告" 
and "規則1-1-3=癌症分期分數或結果為M≠0"
and "規則1-1-4=3個月內有檢查報告"
and "規則1-1-5=Everolimus申請"


//條件2:先前已使用過非類固醇類之芳香環酶抑制劑治療無效
define "規則1-2=先前已使用過非類固醇類之芳香環酶抑制劑治療無效":
  // 至少先前使用過其中一種（L02BG03 或 L02BG04），須在申請之前使用
  (
    Reusable."HasPriorMedicationUse"(CodeConcept.Everolimus, CodeConcept.L02BG03)
    or Reusable."HasPriorMedicationUse"(CodeConcept.Everolimus, CodeConcept.L02BG04)
  )
  and Reusable."醫令類別為1"


//條件3:未曾使用exemestane (申請期間不能使用,但過去可以用過)
define "規則1-3=沒有使用exemestane":
  // 申請期間不能與 exemestane 時間重疊
  not Reusable."HasConcurrentMedicationOrder"(CodeConcept.Everolimus, CodeConcept.L02BG06)

//條件4:荷爾蒙接受體陽性、HER2受體陰性

//條件4-1
define "規則1-4-1=檢驗檢查-荷爾蒙接受體陽性(ER)":
  Reusable."HasMarkerPositiveTest"(CodeConcept.MolecularER)

define "規則1-4-1=基因檢測-荷爾蒙接受體陽性(ER)":
  Reusable."HasMarkerPositiveGene"(CodeConcept.MolecularER)

define "規則1-4-1=荷爾蒙接受體陽性(ER)":
  "規則1-4-1=檢驗檢查-荷爾蒙接受體陽性(ER)"
  or "規則1-4-1=基因檢測-荷爾蒙接受體陽性(ER)"

//條件4-2
define "規則1-4-2=檢驗檢查-荷爾蒙接受體陽性(PR)":
  Reusable."HasMarkerPositiveTest"(CodeConcept.MolecularPR)

define "規則1-4-2=基因檢測-荷爾蒙接受體陽性(PR)":
  Reusable."HasMarkerPositiveGene"(CodeConcept.MolecularPR)

define "規則1-4-2=荷爾蒙接受體陽性(PR)":
  "規則1-4-2=檢驗檢查-荷爾蒙接受體陽性(PR)"
  or "規則1-4-2=基因檢測-荷爾蒙接受體陽性(PR)"

//條件4-3
define "規則1-4-3=檢驗檢查-HER2受體陰性":
  Reusable."HasHER2NegativeTest"

define "規則1-4-3=基因檢測-HER2受體陰性":
  Reusable."HasHER2NegativeGene"

define "規則1-4-3=HER2受體陰性":
  "規則1-4-3=檢驗檢查-HER2受體陰性"
  or "規則1-4-3=基因檢測-HER2受體陰性"

define "規則1-4":
"規則1-4-1=荷爾蒙接受體陽性(ER)"
and "規則1-4-2=荷爾蒙接受體陽性(PR)"
and "規則1-4-3=HER2受體陰性"

//條件5:尚未出現器官轉移危急症狀 (visceral crisis)
define "規則1-5=尚未出現器官轉移危急症狀 (visceral crisis)":
  exists (
    [DiagnosticReport] O
    where exists (
      O.code.coding Cdg
      where (
        Cdg in CodeConcept.ICD10PCS2023Image
        or Cdg in CodeConcept.ICD10PCS2014Image
      )
      and Cdg.code in CodeConcept.ImageCodes
    )
    and O.effective is not null
    and FHIRHelpers.ToDateTime(O.effective) >= "本次申請起始日期" - 180 days
    and FHIRHelpers.ToDateTime(O.effective) <= "本次申請起始日期"
    and O.conclusion is not null
    and Matches(O.conclusion, '(?i).*(no visceral crisis|\\+).*')
  ) 

/*規則2*/
//同 規則1-1-4=3個月內有檢查報告 及 規則1-1-1=3個月內影像報告

//主要規定一
define "主要規定一":
"規則1-1=轉移性乳癌"
and "規則1-2=先前已使用過非類固醇類之芳香環酶抑制劑治療無效"
and "規則1-3=沒有使用exemestane"
and "規則1-4"
and "規則1-5=尚未出現器官轉移危急症狀 (visceral crisis)"


//============================================
// 主要規定二：續用條件－治療持續給付
//============================================

define "本次申請紀錄":
  Reusable."LatestMedicationPlan"(CodeConcept.Everolimus)

define "本次申請起始日期":
  Reusable."GetStartTime"("本次申請紀錄")

//影像證據顯示病情有無惡化
// 取得前次治療紀錄（最近一次已完成的治療）
define "前次治療紀錄":
  Reusable."LatestCompletedMedicationOrderBefore"(CodeConcept.Everolimus, "本次申請起始日期")

// 前次用藥開始日期
define "前次用藥開始日期":
  Reusable."GetStartTime"("前次治療紀錄")

// 條件1:影像證據顯示病情有無惡化
define "規則1=影像證據顯示病情有無惡化":
  Reusable."HasImageReportBetweenPreviousTreatmentAndCurrentApply"(CodeConcept.Everolimus)


// 主要規定二
define "主要規定二":
Reusable."續用註記為2"
and Reusable."醫令類別為1"
and "本次申請紀錄" is not null
and "規則1=影像證據顯示病情有無惡化"



//============================================
// 主要規定三：藥品使用規則
//============================================

//規則1:每次申請之療程以3個月為限
define "規則1=每次申請之療程以3個月為限":
  Reusable."HasMedicationPlanDurationWithin"(CodeConcept.Everolimus, 84)

//規則2:限每日最大劑量為10mg
define "規則2=每日最大劑量為10mg":
  Reusable."HasDailyDoseAtMost"(CodeConcept.Everolimus, 10.0, '{mg}', 'QD')

//主要規定三
define "主要規定三":
"規則1=每次申請之療程以3個月為限" and "規則2=每日最大劑量為10mg"


//============================================
// 列出「符合」項目判斷式
//============================================

define function "符合項目"():
  // 主要規定一：初次使用條件
  (if Reusable."初次申請" and (
    "ICD代碼檢核_布林值" or 
    "醫令類別為1_布林值" or 
    "規則1-1-1=3個月內影像報告" or 
    "規則1-1-3=癌症分期分數或結果為M≠0" or 
    "規則1-1-4=3個月內有檢查報告" or 
    "規則1-1-5=Everolimus申請" or 
    "規則1-2=先前已使用過非類固醇類之芳香環酶抑制劑治療無效" or 
    "規則1-3=沒有使用exemestane" or 
    "規則1-4" or 
    "規則1-5=尚未出現器官轉移危急症狀 (visceral crisis)"
  )
    then '<主要規定一：初次使用條件>\n' +
         (if "ICD代碼檢核_布林值" 
           then '● ICD代碼檢核：主要疾病之ICD代碼使用C50\n' else '') +
         (if "醫令類別為1_布林值" 
           then '● 醫令類別檢核：醫令類別為1(癌症治療)\n' else '') +
         (if "規則1-1-1=3個月內影像報告" 
           then '● 規則1-1-1：3個月內影像報告\n' else '') +
         (if "規則1-1-3=癌症分期分數或結果為M≠0" 
           then '● 規則1-1-3：癌症分期分數或結果為M≠0(轉移性)\n' else '') +
         (if "規則1-1-4=3個月內有檢查報告" 
           then '● 規則1-1-4：3個月內有檢查報告\n' else '') +
         (if "規則1-1-5=Everolimus申請" 
           then '● 規則1-1-5：Everolimus申請\n' else '') +
         (if "規則1-2=先前已使用過非類固醇類之芳香環酶抑制劑治療無效" 
           then '● 規則1-2：先前已使用過非類固醇類之芳香環酶抑制劑治療\n' else '') +
         (if "規則1-3=沒有使用exemestane" 
           then '● 規則1-3：申請期間未併用exemestane\n' else '') +
         (if "規則1-4-1=荷爾蒙接受體陽性(ER)" 
           then '● 規則1-4-1：荷爾蒙接受體陽性(ER)\n' else '') +
         (if "規則1-4-2=荷爾蒙接受體陽性(PR)" 
           then '● 規則1-4-2：荷爾蒙接受體陽性(PR)\n' else '') +
         (if "規則1-4-3=HER2受體陰性" 
           then '● 規則1-4-3：HER2受體陰性\n' else '') +
         (if "規則1-5=尚未出現器官轉移危急症狀 (visceral crisis)" 
           then '● 規則1-5：尚未出現器官轉移危急症狀(visceral crisis)\n' else '') +
         '\n'
    else '') +
  
  // 主要規定二：續用條件
  (if Reusable."續用申請" and "規則1=影像證據顯示病情有無惡化"
    then '<主要規定二：續用條件－治療持續給付>\n' +
         '● 續用規則1：已檢附影像證據顯示病情狀態，確認無惡化\n' +
         '\n'
    else '') +
  
  // 主要規定三：藥品使用規則
  (if "規則1=每次申請之療程以3個月為限" or 
      "規則2=每日最大劑量為10mg"
    then '<主要規定三：藥品使用規則>\n' +
         (if "規則1=每次申請之療程以3個月為限" 
           then '● 規則3-1：申請療程≤3個月(84天)\n' else '') +
         (if "規則2=每日最大劑量為10mg" 
           then '● 規則3-2：每日劑量≤10mg\n' else '')
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
  (if not "規則1=每次申請之療程以3個月為限" or 
      not "規則2=每日最大劑量為10mg"
    then '<主要規定三：藥品使用規則>\n' +
         (if not "規則1=每次申請之療程以3個月為限" 
           then '▲ 規則3-1：申請療程超過3個月(84天)\n' else '') +
         (if not "規則2=每日最大劑量為10mg" 
           then '▲ 規則3-2：每日劑量超過10mg\n' else '')
    else '')

//============================================
// 列出「不符合」項目判斷式 - 必要資料未填寫
//============================================

define function "不符合項目_必要資料未填寫"():
  // 主要規定一：初次使用條件 - 必要資料未填寫
  (if Reusable."初次申請" and (
    not "規則1-1-1=3個月內影像報告" or 
    not "規則1-1-3=癌症分期分數或結果為M≠0" or 
    not "規則1-1-4=3個月內有檢查報告" or 
    not "規則1-1-5=Everolimus申請" or 
    not "規則1-2=先前已使用過非類固醇類之芳香環酶抑制劑治療無效" or 
    not "規則1-3=沒有使用exemestane" or 
    not "規則1-4" or 
    not "規則1-5=尚未出現器官轉移危急症狀 (visceral crisis)"
  )
    then '<主要規定一：初次使用條件>\n' +
         (if not "規則1-1-1=3個月內影像報告" 
           then '▲ 規則1-1-1：未提供3個月內影像報告\n' else '') +
         (if not "規則1-1-3=癌症分期分數或結果為M≠0" 
           then '▲ 規則1-1-3：未提供癌症分期資料或非轉移性(M=0)\n' else '') +
         (if not "規則1-1-4=3個月內有檢查報告" 
           then '▲ 規則1-1-4：未提供3個月內檢查報告\n' else '') +
         (if not "規則1-1-5=Everolimus申請" 
           then '▲ 規則1-1-5：未提供Everolimus申請資料\n' else '') +
         (if not "規則1-2=先前已使用過非類固醇類之芳香環酶抑制劑治療無效" 
           then '▲ 規則1-2：未提供非類固醇類之芳香環酶抑制劑治療紀錄\n' else '') +
         (if not "規則1-3=沒有使用exemestane" 
           then '▲ 規則1-3：申請期間併用exemestane(禁止併用)\n' else '') +
         (if not "規則1-4-1=荷爾蒙接受體陽性(ER)" 
           then '▲ 規則1-4-1：未提供ER檢測資料或ER非陽性\n' else '') +
         (if not "規則1-4-2=荷爾蒙接受體陽性(PR)" 
           then '▲ 規則1-4-2：未提供PR檢測資料或PR非陽性\n' else '') +
         (if not "規則1-4-3=HER2受體陰性" 
           then '▲ 規則1-4-3：未提供HER2檢測資料或HER2非陰性\n' else '') +
         (if not "規則1-5=尚未出現器官轉移危急症狀 (visceral crisis)" 
           then '▲ 規則1-5：未提供影像資料或已出現器官轉移危急症狀(visceral crisis)\n' else '') +
         '\n'
    else '') +
  
  // 主要規定二：續用條件 - 必要資料未填寫
  (if Reusable."續用申請" and not "規則1=影像證據顯示病情有無惡化"
    then '<主要規定二：續用條件－治療持續給付>\n' +
         '▲ 續用規則1：未提供影像證據或顯示疾病惡化\n' +
         '\n'
    else '')

//============================================
// 審核結果
//============================================

define "乳癌Everolimus申請結果_布林":
  case
    when Reusable."初次申請" then (
      "主要規定一" and
      "主要規定三"
    )
    when Reusable."續用申請" then (
      "主要規定二" and
      "主要規定三"
    )
    else false
  end

define "乳癌Everolimus申請之CQL檢核結果":
  if (
    Reusable."初次申請" and 
    "主要規定一" and
    "主要規定三"
  )
  then '✓通過：初次使用－乳癌 Everolimus 用藥申請'

  else if (
    Reusable."續用申請" and
    "主要規定二" and
    "主要規定三"
  )
  then '✓通過：續用－乳癌 Everolimus 用藥申請'
  else if Reusable."初次申請"
  then '✖不通過：初次使用－乳癌 Everolimus 用藥申請'
  else if Reusable."續用申請"
  then '✖不通過：續用－乳癌 Everolimus 用藥申請'
  else '✖不通過：無法判定申請類型－乳癌 Everolimus 用藥申請'

//============================================
// 報告總結
//============================================

define "報告總結":
  '\n=== 乳癌之Everolimus申請審核報告 ===\n' +
  '\n【申請類型】' + Reusable."申請類型" + '\n' +
  '\n【●符合項目】\n' +
  (if "符合項目"() = '' then '無\n' else "符合項目"()) +
  '\n【▲不符合項目 - 代碼或條件不符】\n' +
  (if "不符合項目_代碼或條件不符"() = '' then '無\n' else "不符合項目_代碼或條件不符"()) +
  '\n【▲不符合項目 - 必要資料未填寫】\n' +
  (if "不符合項目_必要資料未填寫"() = '' then '無\n' else "不符合項目_必要資料未填寫"()) +
  '\n【申請結果】\n' +
  "乳癌Everolimus申請之CQL檢核結果" +
  '\n===============================================\n'
