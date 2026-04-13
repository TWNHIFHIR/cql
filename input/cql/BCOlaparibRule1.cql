//三陰性乳癌_Olaparib給付規定
library BCOlaparibRule1 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

include BCCodeConcept version '1.0.0' called CodeConcept

include BCReusable version '1.0.0' called Reusable

context Patient



//============================================
// 主要規定一：初次使用條件
//============================================

/*規則1*/
//條件1:三陰性轉移性乳癌

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
define "規則1-1-5=Olaparib申請":
  exists (        
    [MedicationRequest] MRPlan
    where MRPlan.intent = 'plan'
      and exists (
        MRPlan.medication.coding Cdg
        where Cdg in CodeConcept.NHIMedication
          and Cdg.code in CodeConcept.L01XK01
      )
  )

define "規則1-1=三陰性轉移性乳癌":
  "ICD代碼檢核_布林值" 
  and "醫令類別為1_布林值" 
  and "規則1-1-5=Olaparib申請"
  and "規則1-1-3=癌症分期分數或結果為M≠0"
  and ("規則1-1-1=3個月內影像報告" or "規則1-1-4=3個月內有檢查報告")


//條件2:單獨使用(註：考量藥品數量繁多，此處僅限縮於不同時使用其他需事前審查之乳癌藥品，不包含傳統化療等)
define "規則1-2=單獨使用(註：考量藥品數量繁多，此處僅限縮於不同時使用其他需事前審查之乳癌藥品，不包含傳統化療等)":
  // 不存在其他需事前審查的乳癌藥品「正在使用中」且時間重疊
  not Reusable."HasConcurrentMedicationOrder"(CodeConcept.L01XK01, CodeConcept."乳癌藥品")

//條件3:曾接受前導性化療或術後輔助性化療或轉移性化療

//條件3-1
define "規則1-3-1=曾接受前導性化療":
  // 先前使用過前導性化療，須在申請之前使用
  Reusable."HasPriorMedicationUse"(CodeConcept.L01XK01, CodeConcept."前導性化療")
  and Reusable."醫令類別為1"
  and Reusable."用藥線別≠1"


//條件3-2
define "規則1-3-2=曾接受術後輔助性化療":
  // 先前使用過術後輔助性化療，須在申請之前使用
  Reusable."HasPriorMedicationUse"(CodeConcept.L01XK01, CodeConcept."術後輔助性化療")
  and Reusable."醫令類別為1"
  and Reusable."用藥線別≠1"


//條件3-3
define "規則1-3-3=曾接受轉移性化療":
  // 先前使用過轉移性化療，須在申請之前使用
  Reusable."HasPriorMedicationUse"(CodeConcept.L01XK01, CodeConcept."轉移性化療")
  and Reusable."醫令類別為1"
  and Reusable."用藥線別≠1"

define "規則1-3=曾接受前導性化療或術後輔助性化療或轉移性化療":
"規則1-3-1=曾接受前導性化療"
or "規則1-3-2=曾接受術後輔助性化療"
or "規則1-3-3=曾接受轉移性化療"

//條件4:具germline BRCA 1/2致病性或疑似致病性突變(含germline BRCA 1/2突變之檢測報告)
define "規則1-4=germline BRCA 1/2致病性或疑似致病性突變":
  exists (
    [Observation] OBs
      where exists (
        OBs.category C
          where exists (
            C.coding Cdg
              where Cdg in CodeConcept.NHIPASSupportingInfoType
                and Cdg.code = 'tests'
          )
      )
      and exists (
        OBs.code.coding Cdg
          where Cdg in CodeConcept.LOINC
            and Cdg.code in CodeConcept.BRCA1or2
      )
      and OBs.value is string
      and Matches(OBs.value as string, '(?i).*(Positive|Pathogenic|Likely Pathogenic).*')
  )
  and Reusable."醫令類別為1"
  and Reusable."用藥線別≠1"

//條件5:ER陰性＆PR陰性＆HER2陰性(含ER、PR、HER2皆為陰性之檢測報告)
//條件5-1
define "規則1-5-1=檢驗檢查-ER陰性":
  Reusable."HasMarkerNegativeWithGeneLoincTest"(CodeConcept.MolecularER)

define "規則1-5-1=基因檢測-ER陰性":
  Reusable."HasMarkerNegativeWithGeneLoincGene"(CodeConcept.MolecularER)

define "規則1-5-1=ER陰性":
  "規則1-5-1=檢驗檢查-ER陰性" or "規則1-5-1=基因檢測-ER陰性"

//條件5-2
define "規則1-5-2=檢驗檢查-PR陰性":
  Reusable."HasMarkerNegativeWithGeneLoincTest"(CodeConcept.MolecularPR)

define "規則1-5-2=基因檢測-PR陰性":
  Reusable."HasMarkerNegativeWithGeneLoincGene"(CodeConcept.MolecularPR)

define "規則1-5-2=PR陰性":
  "規則1-5-2=檢驗檢查-PR陰性" or "規則1-5-2=基因檢測-PR陰性"


//條件5-3
define "規則1-5-3=檢驗檢查-HER2陰性":
  Reusable."HasHER2NegativeTest"

define "規則1-5-3=基因檢測-HER2陰性":
  Reusable."HasHER2NegativeGene"

define "規則1-5-3=HER2陰性":
  "規則1-5-3=檢驗檢查-HER2陰性" or "規則1-5-3=基因檢測-HER2陰性"

define "規則1-5=ER陰性＆PR陰性＆HER2陰性":
"規則1-5-1=ER陰性"
and "規則1-5-2=PR陰性"
and "規則1-5-3=HER2陰性"

/*規則2*/
//ER、PR、HER2皆為陰性之檢測報告 同 "規則1-5=ER陰性＆PR陰性＆HER2陰性"
//germline BRCA 1/2突變之檢測報告 同 "規則1-4=germline BRCA 1/2致病性或疑似致病性突變"

//主要規定一
define "主要規定一":
"規則1-1=三陰性轉移性乳癌"
and "規則1-2=單獨使用(註：考量藥品數量繁多，此處僅限縮於不同時使用其他需事前審查之乳癌藥品，不包含傳統化療等)"
and "規則1-3=曾接受前導性化療或術後輔助性化療或轉移性化療"
and "規則1-4=germline BRCA 1/2致病性或疑似致病性突變"
and "規則1-5=ER陰性＆PR陰性＆HER2陰性"



//============================================
// 主要規定二：續用條件－治療持續給付
//============================================

define "本次申請紀錄":
  Reusable."LatestMedicationPlan"(CodeConcept.L01XK01)

define "本次申請起始日期":
  Reusable."GetStartTime"("本次申請紀錄")

//影像證據顯示病情有無惡化
// 取得前次治療紀錄（最近一次已完成的治療）
define "前次治療紀錄":
  Reusable."LatestCompletedMedicationOrderBefore"(CodeConcept.L01XK01, "本次申請起始日期")

// 前次用藥開始日期
define "前次用藥開始日期":
  Reusable."GetStartTime"("前次治療紀錄")

// 條件1:影像證據顯示病情有無惡化
define "規則1=影像證據顯示病情有無惡化":
  Reusable."HasImageReportBetweenPreviousTreatmentAndCurrentApply"(CodeConcept.L01XK01)


// 主要規定二
define "主要規定二":
Reusable."續用註記為2"
and Reusable."醫令類別為1"
and "本次申請紀錄" is not null
and "規則1=影像證據顯示病情有無惡化"


//============================================
// 主要規定三：藥品使用規則
//============================================

/*規則1*/
//每次申請之療程以3個月為限
define "規則1=每次申請之療程以3個月為限":
  Reusable."HasMedicationPlanDurationWithin"(CodeConcept.L01XK01, 84)

/*規則2*/
//不可忍受talazoparib(其副作用)時（註記），與talazoparib 可互換
//條件1
define "規則2-1-1=無法忍受化療(其副作用)時(有註記)":
  exists (
    [Claim] C
      where exists (
        C.diagnosis D
          where exists (
            D.type.text T
              where Matches(T.value, '(?i).*無法忍受talazoparib副作用.*')
            )
        )
    )

//條件2
define "規則2-1-2=Olaparib、talazoparib二者可轉換":
  Reusable."HasMedicationUse"(CodeConcept.L01XK01)
  or Reusable."HasMedicationUse"(CodeConcept.L01XK04)

//條件3
define "規則2-1-3=Olaparib、talazoparib僅得擇一使用":
  not (
    Reusable."HasMedicationUse"(CodeConcept.L01XK01)
    and Reusable."HasMedicationUse"(CodeConcept.L01XK04)
  )

define "規則2=Olaparib與talazoparib僅得擇一使用，除因耐受性不良，不得互換":
  if "規則2-1-1=無法忍受化療(其副作用)時(有註記)"
    then "規則2-1-2=Olaparib、talazoparib二者可轉換"
  else
    "規則2-1-3=Olaparib、talazoparib僅得擇一使用"

/*規則3*/
define "規則3=Olaparib每日最多使用4粒":
  Reusable."HasDailyDoseAtMost"(CodeConcept.L01XK01, 4.0, '{tbl}', 'QD')

// 主要規定三
define "主要規定三":
"規則1=每次申請之療程以3個月為限"
and "規則2=Olaparib與talazoparib僅得擇一使用，除因耐受性不良，不得互換"
and "規則3=Olaparib每日最多使用4粒"



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
    "規則1-1-5=Olaparib申請" or 
    "規則1-2=單獨使用(註：考量藥品數量繁多，此處僅限縮於不同時使用其他需事前審查之乳癌藥品，不包含傳統化療等)" or 
    "規則1-3=曾接受前導性化療或術後輔助性化療或轉移性化療" or 
    "規則1-4=germline BRCA 1/2致病性或疑似致病性突變" or 
    "規則1-5=ER陰性＆PR陰性＆HER2陰性"
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
         (if "規則1-1-5=Olaparib申請" 
           then '● 規則1-1-5：Olaparib申請\n' else '') +
         (if "規則1-2=單獨使用(註：考量藥品數量繁多，此處僅限縮於不同時使用其他需事前審查之乳癌藥品，不包含傳統化療等)" 
           then '● 規則1-2：單獨使用(不與其他需事前審查之乳癌藥品併用)\n' else '') +
         (if "規則1-3-1=曾接受前導性化療" 
           then '● 規則1-3-1：曾接受前導性化療\n' else '') +
         (if "規則1-3-2=曾接受術後輔助性化療" 
           then '● 規則1-3-2：曾接受術後輔助性化療\n' else '') +
         (if "規則1-3-3=曾接受轉移性化療" 
           then '● 規則1-3-3：曾接受轉移性化療\n' else '') +
         (if "規則1-4=germline BRCA 1/2致病性或疑似致病性突變" 
           then '● 規則1-4：具germline BRCA 1/2致病性或疑似致病性突變\n' else '') +
         (if "規則1-5-1=ER陰性" 
           then '● 規則1-5-1：ER陰性\n' else '') +
         (if "規則1-5-2=PR陰性" 
           then '● 規則1-5-2：PR陰性\n' else '') +
         (if "規則1-5-3=HER2陰性" 
           then '● 規則1-5-3：HER2陰性\n' else '') +
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
      "規則2=Olaparib與talazoparib僅得擇一使用，除因耐受性不良，不得互換" or 
      "規則3=Olaparib每日最多使用4粒"
    then '<主要規定三：藥品使用規則>\n' +
         (if "規則1=每次申請之療程以3個月為限" 
           then '● 規則3-1：申請療程≤3個月(84天)\n' else '') +
         (if "規則2-1-1=無法忍受化療(其副作用)時(有註記)" 
           then '● 規則3-2-1：註記無法忍受talazoparib副作用，可轉換使用\n' else '') +
         (if "規則2-1-3=Olaparib、talazoparib僅得擇一使用" 
           then '● 規則3-2-2：Olaparib與talazoparib僅擇一使用\n' else '') +
         (if "規則3=Olaparib每日最多使用4粒" 
           then '● 規則3-3：每日劑量≤4粒\n' else '')
    else '')

//============================================
// 列出「不符合」項目判斷式 - 代碼或條件不符
//============================================

define function "不符合項目_代碼或條件不符"():
  // 主要規定一：初次使用條件 - 代碼條件不符
  (if Reusable."初次申請" and (
    not "ICD代碼檢核_布林值" or 
    not "醫令類別為1_布林值" or 
    not "規則1-2=單獨使用(註：考量藥品數量繁多，此處僅限縮於不同時使用其他需事前審查之乳癌藥品，不包含傳統化療等)"
  )
    then '<主要規定一：初次使用條件>\n' +
         (if not "ICD代碼檢核_布林值" 
           then '▲ ICD代碼檢核：主要疾病之ICD代碼未使用C50\n' else '') +
         (if not "醫令類別為1_布林值" 
           then '▲ 醫令類別檢核：醫令類別非1\n' else '') +
         (if not "規則1-2=單獨使用(註：考量藥品數量繁多，此處僅限縮於不同時使用其他需事前審查之乳癌藥品，不包含傳統化療等)" 
           then '▲ 規則1-2：不得與其他需事前審查之乳癌藥品併用\n' else '') +
         '\n'
    else '') +
  
  // 主要規定三：藥品使用規則 - 代碼條件不符
  (if not "規則1=每次申請之療程以3個月為限" or 
      not "規則2=Olaparib與talazoparib僅得擇一使用，除因耐受性不良，不得互換" or 
      not "規則3=Olaparib每日最多使用4粒"
    then '<主要規定三：藥品使用規則>\n' +
         (if not "規則1=每次申請之療程以3個月為限" 
           then '▲ 規則3-1：申請療程超過3個月(84天)\n' else '') +
         (if not "規則2=Olaparib與talazoparib僅得擇一使用，除因耐受性不良，不得互換" 
           then '▲ 規則3-2：Olaparib與talazoparib應僅擇一使用，除因耐受性不良不得互換\n' else '') +
         (if not "規則3=Olaparib每日最多使用4粒" 
           then '▲ 規則3-3：每日劑量超過4粒\n' else '')
    else '')

//============================================
// 列出「不符合」項目判斷式 - 必要資料未填寫
//============================================

define function "不符合項目_必要資料未填寫"():
  // 主要規定一：初次使用條件 - 必要資料未填寫
  (if Reusable."初次申請" and (
    not ("規則1-1-1=3個月內影像報告" or "規則1-1-4=3個月內有檢查報告") or 
    not "規則1-1-3=癌症分期分數或結果為M≠0" or 
    not "規則1-1-5=Olaparib申請" or 
    not "規則1-3=曾接受前導性化療或術後輔助性化療或轉移性化療" or 
    not "規則1-4=germline BRCA 1/2致病性或疑似致病性突變" or 
    not "規則1-5=ER陰性＆PR陰性＆HER2陰性"
  )
    then '<主要規定一：初次使用條件>\n' +
         (if not "規則1-1-1=3個月內影像報告" and not "規則1-1-4=3個月內有檢查報告" 
           then '▲ 規則1-1-1/1-1-4：未提供3個月內影像報告或檢查報告\n' else '') +
         (if not "規則1-1-3=癌症分期分數或結果為M≠0" 
           then '▲ 規則1-1-3：未提供癌症分期資料或非轉移性(M=0)\n' else '') +
         (if not "規則1-1-5=Olaparib申請" 
           then '▲ 規則1-1-5：未提供Olaparib申請資料\n' else '') +
         (if not "規則1-3=曾接受前導性化療或術後輔助性化療或轉移性化療" 
           then '▲ 規則1-3：未提供前導性化療或術後輔助性化療或轉移性化療紀錄\n' else '') +
         (if not "規則1-4=germline BRCA 1/2致病性或疑似致病性突變" 
           then '▲ 規則1-4：未提供germline BRCA 1/2致病性或疑似致病性突變檢測報告\n' else '') +
         (if not "規則1-5-1=ER陰性" 
           then '▲ 規則1-5-1：未提供ER檢測資料或ER非陰性\n' else '') +
         (if not "規則1-5-2=PR陰性" 
           then '▲ 規則1-5-2：未提供PR檢測資料或PR非陰性\n' else '') +
         (if not "規則1-5-3=HER2陰性" 
           then '▲ 規則1-5-3：未提供HER2檢測資料或HER2非陰性\n' else '') +
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

define "乳癌Olaparib申請結果_布林":
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

define "乳癌Olaparib申請之CQL檢核結果":
  if (
    Reusable."初次申請" and 
    "主要規定一" and
    "主要規定三"
  )
  then '✓通過：初次使用－乳癌 Olaparib 用藥申請'

  else if (
    Reusable."續用申請" and
    "主要規定二" and
    "主要規定三"
  )
  then '✓通過：續用－三陰性乳癌 Olaparib 用藥申請'
  else if Reusable."初次申請"
  then '✖不通過：初次使用－三陰性乳癌 Olaparib 用藥申請'
  else if Reusable."續用申請"
  then '✖不通過：續用－三陰性乳癌 Olaparib 用藥申請'
  else '✖不通過：無法判定申請類型－三陰性乳癌 Olaparib 用藥申請'

//============================================
// 報告總結
//============================================

define "報告總結":
  '\n=== 三陰性乳癌 Olaparib 申請審核報告 ===\n' +
  '\n【申請類型】' + Reusable."申請類型" + '\n' +
  '\n【●符合項目】\n' +
  (if "符合項目"() = '' then '無\n' else "符合項目"()) +
  '\n【▲不符合項目 - 代碼或條件不符】\n' +
  (if "不符合項目_代碼或條件不符"() = '' then '無\n' else "不符合項目_代碼或條件不符"()) +
  '\n【▲不符合項目 - 必要資料未填寫】\n' +
  (if "不符合項目_必要資料未填寫"() = '' then '無\n' else "不符合項目_必要資料未填寫"()) +
  '\n【申請結果】\n' +
  "乳癌Olaparib申請之CQL檢核結果" +
  '\n===============================================\n'
