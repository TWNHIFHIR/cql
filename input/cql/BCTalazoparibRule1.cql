//乳癌_Talazoparib給付規定
library BCTalazoparibRule1 version '1.0.0'

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

//條件1:局部晚期或轉移性三陰性乳癌
//條件1-1
define "條件1-1=3個月內影像報告":
  Reusable."HasRecentImageReport"("本次申請起始日期", 90)


//條件1-2
define "條件1-2=癌症分期分數或結果為M≠0":
  Reusable."癌症分期分數或結果為M≠0"

//條件1-3(檢查報告)
define "條件1-3=3個月內有檢查報告":
  Reusable."HasRecentMolecularReport"("本次申請起始日期", 90)

//條件1-4
define "條件1-4=Talazoparib申請":
  exists (        
    [MedicationRequest] MRPlan
    where MRPlan.intent = 'plan'
      and exists (
        MRPlan.medication.coding Cdg
        where Cdg in CodeConcept.NHIMedication
          and Cdg.code in CodeConcept.L01XK04
      )
  )

define "規則1-1=局部晚期或轉移性三陰性乳癌":
  "ICD代碼檢核_布林值" 
  and "醫令類別為1_布林值" 
  and "條件1-4=Talazoparib申請"
  and "條件1-2=癌症分期分數或結果為M≠0"
  and ("條件1-1=3個月內影像報告" or "條件1-3=3個月內有檢查報告")

define "年齡計算用申請日期":
  date from "本次申請起始日期"

define "申請日時病人年齡歲數":
  if Patient.birthDate is null or "年齡計算用申請日期" is null then null
  else difference in years between
    FHIRHelpers.ToDate(Patient.birthDate)
    and "年齡計算用申請日期"

define "是否滿18歲":
  if "申請日時病人年齡歲數" is null then false
  else "申請日時病人年齡歲數" >= 18


//條件2:18歲以上
define "規則1-2=18歲以上":
  Patient.birthDate is not null
  and "是否滿18歲"


//條件3
//條件3-1:曾接受前導性化療
define "條件3-1=曾接受前導性化療":
  Reusable."醫令類別為1"
  // 先前使用過前導性化療，須在申請之前使用
  and Reusable."HasPriorMedicationUse"(CodeConcept.L01XK04, CodeConcept."前導性化療")

//條件3-2:曾接受術後輔助性化療
define "條件3-2=曾接受術後輔助性化療":
  Reusable."醫令類別為1"
  // 先前使用過術後輔助性化療，須在申請之前使用
  and Reusable."HasPriorMedicationUse"(CodeConcept.L01XK04, CodeConcept."術後輔助性化療")

//條件3-3:曾接受轉移性化療
define "條件3-3=曾接受轉移性化療":
  Reusable."醫令類別為1"
  // 先前使用過轉移性化療，須在申請之前使用
  and Reusable."HasPriorMedicationUse"(CodeConcept.L01XK04, CodeConcept."轉移性化療")

define "規則1-3":
"條件3-1=曾接受前導性化療" or "條件3-2=曾接受術後輔助性化療" or "條件3-3=曾接受轉移性化療"

//條件4:具germline BRCA 1/2突變
define "規則1-4/規則2-2=具germline BRCA 1/2突變":
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

//條件5
//條件5-1:ER陰性
define "條件5-1=檢驗檢查-ER陰性":
  Reusable."HasTestObservationWithInterpretationAndValuePattern"(CodeConcept.MolecularER, { 'NEG' }, '(?i).*([-−]|0|陰性|negative).*')

define "條件5-1=基因檢測-ER陰性":
  Reusable."HasGeneInfoObservationWithInterpretationAndTextPattern"(CodeConcept.MolecularER, { 'NEG' }, '(?i).*([-−]|0|陰性|negative).*')

define "條件5-1=ER陰性":
  Reusable."HasMarkerNegative"(CodeConcept.MolecularER)

//條件5-2:PR陰性
define "條件5-2=檢驗檢查-PR陰性":
  Reusable."HasTestObservationWithInterpretationAndValuePattern"(CodeConcept.MolecularPR, { 'NEG' }, '(?i).*([-−]|0|陰性|negative).*')

define "條件5-2=基因檢測-PR陰性":
  Reusable."HasMarkerNegativeGene"(CodeConcept.MolecularPR)

define "條件5-2=PR陰性":
  Reusable."HasMarkerNegativeWithGeneLoinc"(CodeConcept.MolecularPR)


//條件5-3:HER2陰性
define "條件5-3=檢驗檢查-HER2陰性":
  Reusable."HasTestObservationWithInterpretationAndValuePattern"(CodeConcept.HER2, { 'NEG' }, '(?i).*([-−]|0|陰性|negative).*')

define "條件5-3=基因檢測-HER2陰性":
  Reusable."HasHER2NegativeGene"

define "條件5-3=HER2陰性":
  Reusable."HasHER2Negative"

define "規則1-5/規則2-1=ER陰性&PR陰性&HER2陰性":
"條件5-1=ER陰性" and "條件5-2=PR陰性" and "條件5-3=HER2陰性"


//主要規定一
define "主要規定一":
"規則1-1=局部晚期或轉移性三陰性乳癌"
and "規則1-2=18歲以上"
and "規則1-3"
and "規則1-4/規則2-2=具germline BRCA 1/2突變"
and "規則1-5/規則2-1=ER陰性&PR陰性&HER2陰性"


//============================================
// 主要規定二：續用條件－治療持續給付
//============================================

define "本次申請紀錄":
  Reusable."LatestMedicationPlan"(CodeConcept.L01XK04)

define "本次申請起始日期":
  Reusable."GetStartTime"("本次申請紀錄")


//影像證據顯示病情有無惡化
// 取得前次治療紀錄（最近一次已完成的治療）
define "前次治療紀錄":
  Reusable."LatestCompletedMedicationOrderBefore"(CodeConcept.L01XK04, "本次申請起始日期")

// 前次用藥開始日期
define "前次用藥開始日期":
  Reusable."GetStartTime"("前次治療紀錄")

// 條件1:影像證據顯示病情有無惡化
define "規則1=影像證據顯示病情有無惡化":
  Reusable."HasImageReportBetweenPreviousTreatmentAndCurrentApply"(CodeConcept.L01XK04)


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
  Reusable."HasMedicationPlanDurationWithin"(CodeConcept.L01XK04, 84)


/*規則2*/
//不可忍受talazoparib(其副作用)時（註記），與talazoparib 可互換
//條件2-1
define "條件2-1=無法忍受化療(其副作用)時(有註記)":
  exists (
    [Claim] C
      where exists (
        C.diagnosis D
          where exists (
            D.type.text T
              where Matches(T.value, '(?i).*無法忍受Olaparib副作用.*')
            )
        )
    )

//條件2-2
define "條件2-2=Talazoparib、Olaparib二者可轉換":
  Reusable."HasMedicationUse"(CodeConcept.L01XK01)
  or Reusable."HasMedicationUse"(CodeConcept.L01XK04)


//條件2-3
define "條件2-3=Talazoparib、Olaparib僅得擇一使用":
  not (
    Reusable."HasMedicationUse"(CodeConcept.L01XK01)
    and Reusable."HasMedicationUse"(CodeConcept.L01XK04)
  )


define "規則2=Talazoparib與Olaparib僅得擇一使用":
  if "條件2-1=無法忍受化療(其副作用)時(有註記)"
    then "條件2-2=Talazoparib、Olaparib二者可轉換"
  else
    "條件2-3=Talazoparib、Olaparib僅得擇一使用"



// 主要規定三
define "主要規定三":
"規則1=每次申請之療程以3個月為限"
and "規則2=Talazoparib與Olaparib僅得擇一使用"


//============================================
// 列出「符合」項目判斷式
//============================================

define function "符合項目"():
  // 主要規定一：初次使用條件
  (if Reusable."初次申請" and (
    "規則1-1=局部晚期或轉移性三陰性乳癌" or 
    "規則1-2=18歲以上" or 
    "規則1-3" or 
    "規則1-4/規則2-2=具germline BRCA 1/2突變" or 
    "規則1-5/規則2-1=ER陰性&PR陰性&HER2陰性"
  )
    then '<主要規定一：初次使用條件>\n' +
         (if "ICD代碼檢核_布林值" 
           then '● 規則1-1-0：ICD代碼為C50\n' else '') +
         (if "條件1-1=3個月內影像報告" 
           then '● 規則1-1-1：3個月內影像報告\n' else '') +
         (if "條件1-2=癌症分期分數或結果為M≠0" 
           then '● 規則1-1-2：癌症分期分數或結果為M≠0（轉移性）\n' else '') +
         (if "條件1-3=3個月內有檢查報告" 
           then '● 規則1-1-3：3個月內有檢查報告\n' else '') +
         (if "條件1-4=Talazoparib申請" 
           then '● 規則1-1-4：Talazoparib申請\n' else '') +
         (if "規則1-2=18歲以上" 
           then '● 規則1-2：18歲以上\n' else '') +
         (if "條件3-1=曾接受前導性化療" 
           then '● 規則1-3-1：曾接受前導性化療\n' else '') +
         (if "條件3-2=曾接受術後輔助性化療" 
           then '● 規則1-3-2：曾接受術後輔助性化療\n' else '') +
         (if "條件3-3=曾接受轉移性化療" 
           then '● 規則1-3-3：曾接受轉移性化療\n' else '') +
         (if "規則1-4/規則2-2=具germline BRCA 1/2突變" 
           then '● 規則1-4：具germline BRCA 1/2突變\n' else '') +
         (if "條件5-1=ER陰性" 
           then '● 規則1-5-1：ER陰性\n' else '') +
         (if "條件5-2=PR陰性" 
           then '● 規則1-5-2：PR陰性\n' else '') +
         (if "條件5-3=HER2陰性" 
           then '● 規則1-5-3：HER2陰性\n' else '') +
         '\n'
    else '') +
  
  // 主要規定二：續用條件
  (if Reusable."續用申請" and "規則1=影像證據顯示病情有無惡化"
    then '<主要規定二：續用條件－治療持續給付>\n' +
         '● 續用規則1：已檢附前次治療後影像學報告，確認無惡化\n' +
         '\n'
    else '') +
  
  // 主要規定三：藥品使用規則
  (if "規則1=每次申請之療程以3個月為限" or "規則2=Talazoparib與Olaparib僅得擇一使用"
    then '<主要規定三：藥品使用規則>\n' +
         (if "規則1=每次申請之療程以3個月為限" 
           then '● 規則3-1：每次申請之療程≤3個月（84天）\n' else '') +
         (if "條件2-1=無法忍受化療(其副作用)時(有註記)" and "條件2-2=Talazoparib、Olaparib二者可轉換"
           then '● 規則3-2：無法忍受Olaparib副作用，Talazoparib與Olaparib二者可轉換\n' 
           else if "條件2-3=Talazoparib、Olaparib僅得擇一使用"
           then '● 規則3-2：Talazoparib與Olaparib僅得擇一使用\n' 
           else '')
    else '')

//============================================
// 列出「不符合」項目判斷式 - 代碼或條件不符
//============================================

define function "不符合項目_代碼或條件不符"():
  // 主要規定一：初次使用條件 - 代碼條件不符
  (if Reusable."初次申請" and (
    not "ICD代碼檢核_布林值" or 
    not "條件1-2=癌症分期分數或結果為M≠0" or 
    not "規則1-2=18歲以上"
  )
    then '<主要規定一：初次使用條件>\n' +
         (if not "ICD代碼檢核_布林值" 
           then '▲ 規則1-1-0：主要疾病之ICD代碼未使用C50\n' else '') +
         (if not "條件1-2=癌症分期分數或結果為M≠0" 
           then '▲ 規則1-1-2：癌症分期分數或結果不為M≠0（非轉移性）\n' else '') +
         (if not "規則1-2=18歲以上" 
           then '▲ 規則1-2：非18歲以上患者\n' else '') +
         '\n'
    else '') +
  
  // 主要規定三：藥品使用規則 - 代碼條件不符
  (if not "規則1=每次申請之療程以3個月為限" or not "規則2=Talazoparib與Olaparib僅得擇一使用"
    then '<主要規定三：藥品使用規則>\n' +
         (if not "規則1=每次申請之療程以3個月為限" 
           then '▲ 規則3-1：每次申請之療程超過3個月（84天）\n' else '') +
         (if "條件2-1=無法忍受化療(其副作用)時(有註記)" and not "條件2-2=Talazoparib、Olaparib二者可轉換"
           then '▲ 規則3-2：標註無法忍受Olaparib副作用但未正確使用Talazoparib或Olaparib\n' 
           else if not "條件2-1=無法忍受化療(其副作用)時(有註記)" and not "條件2-3=Talazoparib、Olaparib僅得擇一使用"
           then '▲ 規則3-2：同時使用Talazoparib與Olaparib\n' 
           else '')
    else '')

//============================================
// 列出「不符合」項目判斷式 - 必要資料未填寫
//============================================

define function "不符合項目_必要資料未填寫"():
  // 主要規定一：初次使用條件 - 必要資料未填寫
  (if Reusable."初次申請" and (
    not "條件1-4=Talazoparib申請" or 
    not ("條件1-1=3個月內影像報告" or "條件1-3=3個月內有檢查報告") or 
    not "規則1-3" or 
    not "規則1-4/規則2-2=具germline BRCA 1/2突變" or 
    not "規則1-5/規則2-1=ER陰性&PR陰性&HER2陰性"
  )
    then '<主要規定一：初次使用條件>\n' +
         (if not "條件1-4=Talazoparib申請" 
           then '▲ 規則1-1-4：未申請Talazoparib\n' else '') +
         (if not ("條件1-1=3個月內影像報告" or "條件1-3=3個月內有檢查報告") 
           then '▲ 規則1-1-1/1-1-3：未提供3個月內影像報告或檢查報告\n' else '') +
         (if not "規則1-3" 
           then '▲ 規則1-3：未提供前導性化療、術後輔助性化療或轉移性化療紀錄\n' +
                (if not "條件3-1=曾接受前導性化療" and not "條件3-2=曾接受術後輔助性化療" and not "條件3-3=曾接受轉移性化療"
                  then '  - 未提供任何化療紀錄\n' else '')
           else '') +
         (if not "規則1-4/規則2-2=具germline BRCA 1/2突變" 
           then '▲ 規則1-4：未提供germline BRCA 1/2突變檢測資料\n' else '') +
         (if not "規則1-5/規則2-1=ER陰性&PR陰性&HER2陰性" 
           then '▲ 規則1-5：未符合三陰性乳癌條件（需ER陰性、PR陰性、HER2陰性）\n' +
                (if not "條件5-1=ER陰性"
                  then '  - ER非陰性或未提供ER檢測資料\n' else '') +
                (if not "條件5-2=PR陰性"
                  then '  - PR非陰性或未提供PR檢測資料\n' else '') +
                (if not "條件5-3=HER2陰性"
                  then '  - HER2非陰性或未提供HER2檢測資料\n' else '')
           else '') +
         '\n'
    else '') +
  
  // 主要規定二：續用條件 - 必要資料未填寫
  (if Reusable."續用申請" and not "規則1=影像證據顯示病情有無惡化"
    then '<主要規定二：續用條件－治療持續給付>\n' +
         '▲ 續用規則1：未提供前次治療後影像學報告或顯示疾病惡化\n' +
         '\n'
    else '')

//============================================
// 審核結果
//============================================

define "乳癌Talazoparib申請結果_布林":
  case
    when Reusable."初次申請" then (
      "規則1-1=局部晚期或轉移性三陰性乳癌" and
      "規則1-2=18歲以上" and
      "規則1-3" and
      "規則1-4/規則2-2=具germline BRCA 1/2突變" and
      "規則1-5/規則2-1=ER陰性&PR陰性&HER2陰性" and
      "規則1=每次申請之療程以3個月為限" and
      "規則2=Talazoparib與Olaparib僅得擇一使用"
    )
    when Reusable."續用申請" then (
      "規則1=影像證據顯示病情有無惡化" and
      "規則1=每次申請之療程以3個月為限" and
      "規則2=Talazoparib與Olaparib僅得擇一使用"
    )
    else false
  end

define "乳癌Talazoparib申請之CQL檢核結果":
  if (
    Reusable."初次申請" and 
    "規則1-1=局部晚期或轉移性三陰性乳癌" and
    "規則1-2=18歲以上" and
    "規則1-3" and
    "規則1-4/規則2-2=具germline BRCA 1/2突變" and
    "規則1-5/規則2-1=ER陰性&PR陰性&HER2陰性" and
    "規則1=每次申請之療程以3個月為限" and
    "規則2=Talazoparib與Olaparib僅得擇一使用"
  )
  then '✓通過：初次使用－早期乳癌 Talazoparib 用藥申請'

  else if (
    Reusable."續用申請" and
    "規則1=影像證據顯示病情有無惡化" and
    "規則1=每次申請之療程以3個月為限" and
    "規則2=Talazoparib與Olaparib僅得擇一使用"
  )
  then '✓通過：續用－早期乳癌 Talazoparib 用藥申請'
  
  else if Reusable."初次申請"
  then '✖不通過：初次使用－早期乳癌 Talazoparib 用藥申請'
  
  else if Reusable."續用申請"
  then '✖不通過：續用－早期乳癌 Talazoparib 用藥申請'
  
  else '✖不通過：無法判定申請類型－早期乳癌 Talazoparib 用藥申請'

//============================================
// 報告總結
//============================================

define "報告總結":
  '\n=== 早期乳癌之 Talazoparib 申請審核報告 ===\n' +
  '\n【申請類型】' + Reusable."申請類型" + '\n' +
  '\n【年齡檢核】' +
  '申請日時病人年齡歲數：' +
  Coalesce(ToString("申請日時病人年齡歲數"), '無法計算') + '\n' +
  '\n【●符合項目】\n' +
  (if "符合項目"() = '' then '無\n' else "符合項目"()) +
  '\n【▲不符合項目 - 代碼或條件不符】\n' +
  (if "不符合項目_代碼或條件不符"() = '' then '無\n' else "不符合項目_代碼或條件不符"()) +
  '\n【▲不符合項目 - 必要資料未填寫】\n' +
  (if "不符合項目_必要資料未填寫"() = '' then '無\n' else "不符合項目_必要資料未填寫"()) +
  '\n【申請結果】\n' +
  "乳癌Talazoparib申請之CQL檢核結果" +
  '\n===============================================\n'
