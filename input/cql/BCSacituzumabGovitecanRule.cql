//乳癌_Sacituzumab govitecan給付規定
library BCSacituzumabGovitecanRule version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

include BCCodeConcept version '1.0.0' called CodeConcept

include BCReusable version '1.0.0' called Reusable

context Patient


define "本次申請紀錄":
  Reusable."LatestMedicationPlan"(CodeConcept.L01FX17)

define "本次申請起始日期":
  Reusable."GetStartTime"("本次申請紀錄")

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



//============================================
// 主要規定一：初次使用條件
//============================================

/*規則1*/

//1條件1:適用於治療先前已接受兩次以上全身性治療無效(其中一次需為治療晚期疾病)
define "條件1=適用於治療先前已接受兩次以上全身性治療無效":
    exists (
        [Claim] C
        where exists (
            C.diagnosis D
            where exists (
                D.type.text T
                where Matches(T.value, '(?i).*(待諮詢醫師\\+).*')
            )
        )
    )


//1條件2:無法切除的局部晚期或轉移性的三陰性乳癌成年病人

define "ICD代碼檢核_布林值": Reusable."ICD-10使用C50"

define "醫令類別為1_布林值":Reusable."醫令類別為1"

//1條件2-1
define "1條件2-1=無法切除的局部晚期或轉移性的乳癌成年病人":
  Patient.birthDate is not null
  and "是否滿18歲"

//1條件2-2
define "1條件2-2=病摘應敘明無法切除":
    exists (
        [Claim] C
        where exists (
            C.diagnosis D
            where exists (
                D.type.text T
                where Matches(T.value, '(?i).*(無法切除\\+).*')
            )
        )
    )


//1條件2-3
define "1條件2-3=癌症分期分數或結果為M>=1":
  exists (
    [Observation] O
      where exists (
        O.code.coding Cdg
          where Cdg.code = '399390009'
            and Cdg in CodeConcept.SNOMED
      )
        and O.value is not null
        and O.value is FHIR.string
        and Matches((O.value as FHIR.string).value, '.*M[^0].*')
  )


//1條件2-4
define "1條件2-4/2條件1=ER陰性":
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
            and Cdg.code in CodeConcept.MolecularER
      )
      and exists (
        OBs.interpretation.coding INT
          where INT in CodeConcept.InterpretationCodes
            and INT.code in {'NEG'}
      )
      and OBs.value is string
      and Matches(OBs.value as string, '(?i).*([-−]|0|陰性|negative).*')
      and ((OBs.effective is FHIR.dateTime
        and FHIRHelpers.ToDateTime(OBs.effective as FHIR.dateTime) >= "本次申請起始日期" - 90 days
        and FHIRHelpers.ToDateTime(OBs.effective as FHIR.dateTime) <= "本次申請起始日期"
        )
    )
  )
  or exists (
    [Observation] OBs
      where exists (
        OBs.category C
          where exists (
            C.coding Cdg
              where Cdg in CodeConcept.NHIPASSupportingInfoType
                and Cdg.code = 'geneInfo'
          )
      )
    and exists (
      OBs.code.coding Cdg
      where Cdg in CodeConcept.LOINC
      and Cdg.code = '69548-6'
    )
    and exists (
      OBs.component Comp
        where exists (
          Comp.code.coding Cdg
            where Cdg in CodeConcept.LOINC
              and Cdg.code in CodeConcept.MolecularER
        )
        and exists (
          Comp.interpretation.coding INT
            where INT in CodeConcept.InterpretationCodes
              and INT.code in {'NEG'}
        )
        and exists (
          Comp.interpretation I
            where Matches(I.text, '(?i).*([-−]|0|陰性|negative).*')
        )
    )
    and ((OBs.effective is FHIR.dateTime
      and FHIRHelpers.ToDateTime(OBs.effective as FHIR.dateTime) >= "本次申請起始日期" - 90 days
      and FHIRHelpers.ToDateTime(OBs.effective as FHIR.dateTime) <= "本次申請起始日期"
      )
    )
  )

//1條件2-5
define "1條件2-5/2條件1=PR陰性":
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
            and Cdg.code in CodeConcept.MolecularPR
      )
      and exists (
        OBs.interpretation.coding INT
          where INT in CodeConcept.InterpretationCodes
            and INT.code in {'NEG'}
      )
      and OBs.value is string
      and Matches(OBs.value as string, '(?i).*([-−]|0|陰性|negative).*')
      and ((OBs.effective is FHIR.dateTime
        and FHIRHelpers.ToDateTime(OBs.effective as FHIR.dateTime) >= "本次申請起始日期" - 90 days
        and FHIRHelpers.ToDateTime(OBs.effective as FHIR.dateTime) <= "本次申請起始日期"
        )
      )
  )
  or exists (
    [Observation] OBs
      where exists (
        OBs.category C
          where exists (
            C.coding Cdg
              where Cdg in CodeConcept.NHIPASSupportingInfoType
                and Cdg.code = 'geneInfo'
          )
      )
    and exists (
      OBs.code.coding Cdg
      where Cdg in CodeConcept.LOINC
      and Cdg.code = '69548-6'
    )
    and exists (
      OBs.component Comp
        where exists (
          Comp.code.coding Cdg
            where Cdg in CodeConcept.LOINC
              and Cdg.code in CodeConcept.MolecularPR
        )
        and exists (
          Comp.interpretation.coding INT
            where INT in CodeConcept.InterpretationCodes
              and INT.code in {'NEG'}
        )
    )
  )


//1條件2-6
define "1條件2-6/2條件1=檢驗檢查-HER2陰性":
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
            and Cdg.code in CodeConcept.HER2
      )
      and exists (
        OBs.interpretation.coding INT
          where INT in CodeConcept.InterpretationCodes
            and INT.code in {'NEG'}
      )
      and OBs.value is string
      and Matches(OBs.value as string, '(?i).*([-−]|0|陰性|negative).*')
      and ((OBs.effective is FHIR.dateTime
        and FHIRHelpers.ToDateTime(OBs.effective as FHIR.dateTime) >= "本次申請起始日期" - 90 days
        and FHIRHelpers.ToDateTime(OBs.effective as FHIR.dateTime) <= "本次申請起始日期"
        )
    )
  )

define "1條件2-6/2條件1=基因檢測-HER2陰性":
  exists (
    [Observation] OBs
      where exists (
        OBs.category C
          where exists (
            C.coding Cdg
              where Cdg in CodeConcept.NHIPASSupportingInfoType
                and Cdg.code = 'geneInfo'
          )
      )
    and exists (
      OBs.code.coding Cdg
      where Cdg in CodeConcept.LOINC
      and Cdg.code = '69548-6'
    )
    and exists (
      OBs.component Comp
        where exists (
          Comp.code.coding Cdg
            where Cdg in CodeConcept.LOINC
              and Cdg.code in CodeConcept.HER2
        )
        and exists (
          Comp.interpretation.coding INT
            where INT in CodeConcept.InterpretationCodes
              and INT.code in {'NEG'}
        )
        and exists (
          Comp.interpretation I
            where Matches(I.text, '(?i).*([-−]|0|陰性|negative).*')
        )
    )
    and ((OBs.effective is FHIR.dateTime
      and FHIRHelpers.ToDateTime(OBs.effective as FHIR.dateTime) >= "本次申請起始日期" - 90 days
      and FHIRHelpers.ToDateTime(OBs.effective as FHIR.dateTime) <= "本次申請起始日期"
      )
    )
  )

define "1條件2-6/2條件1=HER2陰性":
  "1條件2-6/2條件1=檢驗檢查-HER2陰性" or "1條件2-6/2條件1=基因檢測-HER2陰性"


define "1條件2=無法切除的局部晚期或轉移性的三陰性乳癌成年病人":
"ICD代碼檢核_布林值" and "醫令類別為1_布林值"
and "1條件2-1=無法切除的局部晚期或轉移性的乳癌成年病人"
and "1條件2-2=病摘應敘明無法切除"
and "1條件2-3=癌症分期分數或結果為M>=1"
and "1條件2-4/2條件1=ER陰性"
and "1條件2-5/2條件1=PR陰性"
and "1條件2-6/2條件1=HER2陰性"


//1條件3:病人身體狀況良好（ECOG <= 1）
define "1條件3=病人身體狀況良好(ECOG≦1)":
  exists (
    [Observation] OBs
    where exists (
      OBs.category C
      where exists (
        C.coding Cdg
        where Cdg in CodeConcept.NHIPASSupportingInfoType
        and Cdg.code = 'patientAssessment'
      )
    )
    and exists (
      OBs.code.coding Cdg
      where Cdg in CodeConcept.LOINC
      and Cdg.code = '89247-1'
    )
    and OBs.value is FHIR.integer
    and (OBs.value as FHIR.integer) <= 1
  )


//1條件4:須使用過taxane類藥物至少1個療程
define "1條件4=須使用過taxane類藥物至少1個療程":
  // 先前使用過 taxane (L01CD01 或 L01CD02)，須在申請之前使用
  (
    Reusable."HasPriorMedicationUse"(CodeConcept.L01FX17, CodeConcept.L01CD02)
    or Reusable."HasPriorMedicationUse"(CodeConcept.L01FX17, CodeConcept.L01CD01)
  )
  and Reusable."醫令類別為1"


//1條件5:先前未接受過trastuzumab deruxtecan治療
define "1條件2-2=先前未接受過trastuzumab deruxtecan治療":
  not exists (
    [MedicationRequest] MR
    where (MR.intent = 'plan' or MR.intent = 'order')
    and exists (
      MR.medication.coding Cdg
      where Cdg in CodeConcept.NHIMedication
      and Cdg.code in CodeConcept.L01FD04
    )
    and Reusable."HasValidTiming"(MR)
  )


//主要規定一
define "主要規定一":
"條件1=適用於治療先前已接受兩次以上全身性治療無效"
and "1條件2=無法切除的局部晚期或轉移性的三陰性乳癌成年病人"
and "1條件3=病人身體狀況良好(ECOG≦1)"
and "1條件4=須使用過taxane類藥物至少1個療程"
and "1條件2-2=先前未接受過trastuzumab deruxtecan治療"



//============================================
// 主要規定二：續用條件－治療持續給付
//============================================

/*規則1*/
define "規則1=再次申請必須提出客觀證據（如：影像學）證實無惡化，才可繼續使用":
  exists (
    [MedicationRequest] MRPlan
     where MRPlan.intent = 'plan'
     and exists (
        MRPlan.medication.coding Cdg
        where Cdg in CodeConcept.NHIMedication
        and Cdg.code in CodeConcept.L01FX17
      )
  and exists (
    [DiagnosticReport] Report
     where exists (
      Report.code.coding Cdg
        where (
          Cdg in CodeConcept.ICD10PCS2023Image
          or Cdg in CodeConcept.ICD10PCS2014Image
        )
        and Cdg.code in CodeConcept.ImageCodes
      )
      and Report.effective is not null
      and FHIRHelpers.ToDateTime(Report.effective) >= "本次申請起始日期" - 90 days
      and FHIRHelpers.ToDateTime(Report.effective) <= "本次申請起始日期"
      )
      
    )
  and Reusable."醫令類別為1"

define "主要規定二":
  Reusable."續用申請"
  and Reusable."醫令類別為1"
  and "本次申請紀錄" is not null
  and "規則1=再次申請必須提出客觀證據（如：影像學）證實無惡化，才可繼續使用"


//============================================
// 主要規定三：藥品使用規則
//============================================

/*規則1*/

//規則1:每次申請之療程以3個月為限
define "藥品規則1=每次申請之療程以3個月為限":
  Reusable."HasMedicationPlanDurationWithin"(CodeConcept.L01FX17, 84)


//規則2:Sacituzumab govitecan和trastuzumab deruxtecan僅能擇一給付，不得互換
define "藥品規則2=Sacituzumab govitecan和trastuzumab deruxtecan僅能擇一給付":
  not (
    Reusable."HasMedicationUse"(CodeConcept.L01FX17)
    and Reusable."HasMedicationUse"(CodeConcept.L01FD04)
  )


// 主要規定三
define "主要規定三":
"藥品規則1=每次申請之療程以3個月為限" and "藥品規則2=Sacituzumab govitecan和trastuzumab deruxtecan僅能擇一給付"


//============================================
// 列出「符合」項目判斷式
//============================================

define function "符合項目"():
  // 主要規定一：初次使用條件
  (if Reusable."初次申請" and (
    "條件1=適用於治療先前已接受兩次以上全身性治療無效" or 
    "1條件2=無法切除的局部晚期或轉移性的三陰性乳癌成年病人" or 
    "1條件3=病人身體狀況良好(ECOG≦1)" or 
    "1條件4=須使用過taxane類藥物至少1個療程" or 
    "1條件2-2=先前未接受過trastuzumab deruxtecan治療"
  )
    then '<主要規定一：初次使用條件>\n' +
         (if "條件1=適用於治療先前已接受兩次以上全身性治療無效" 
           then '● 規則1-條件1：先前已接受兩次以上全身性治療無效（其中一次需為治療晚期疾病）\n' else '') +
         (if "ICD代碼檢核_布林值" 
           then '● 規則1-條件2-0：ICD代碼為C50\n' else '') +
         (if "1條件2-1=無法切除的局部晚期或轉移性的乳癌成年病人" 
           then '● 規則1-條件2-1：成年患者（≥18歲）\n' else '') +
         (if "1條件2-2=病摘應敘明無法切除" 
           then '● 規則1-條件2-2：病摘敘明無法切除\n' else '') +
         (if "1條件2-3=癌症分期分數或結果為M>=1" 
           then '● 規則1-條件2-3：癌症分期分數或結果為M≥1（轉移性）\n' else '') +
         (if "1條件2-4/2條件1=ER陰性" 
           then '● 規則1-條件2-4：ER陰性（3個月內檢測）\n' else '') +
         (if "1條件2-5/2條件1=PR陰性" 
           then '● 規則1-條件2-5：PR陰性（3個月內檢測）\n' else '') +
         (if "1條件2-6/2條件1=HER2陰性" 
           then '● 規則1-條件2-6：HER2陰性（3個月內檢測）\n' else '') +
         (if "1條件3=病人身體狀況良好(ECOG≦1)" 
           then '● 規則1-條件3：病人身體狀況良好（ECOG≤1）\n' else '') +
         (if "1條件4=須使用過taxane類藥物至少1個療程" 
           then '● 規則1-條件4：已使用過taxane類藥物至少1個療程\n' else '') +
         (if "1條件2-2=先前未接受過trastuzumab deruxtecan治療" 
           then '● 規則1-條件5：先前未接受過trastuzumab deruxtecan治療\n' else '') +
         '\n'
    else '') +
  
  // 主要規定二：續用條件
  (if Reusable."續用申請" and "規則1=再次申請必須提出客觀證據（如：影像學）證實無惡化，才可繼續使用"
    then '<主要規定二：續用條件－治療持續給付>\n' +
         '● 續用規則1：已檢附客觀證據（如：影像學）證實無惡化\n' +
         '\n'
    else '') +
  
  // 主要規定三：藥品使用規則
  (if "藥品規則1=每次申請之療程以3個月為限" or "藥品規則2=Sacituzumab govitecan和trastuzumab deruxtecan僅能擇一給付"
    then '<主要規定三：藥品使用規則>\n' +
         (if "藥品規則1=每次申請之療程以3個月為限" 
           then '● 規則3-1：每次申請之療程≤3個月（84天）\n' else '') +
         (if "藥品規則2=Sacituzumab govitecan和trastuzumab deruxtecan僅能擇一給付" 
           then '● 規則3-2：Sacituzumab govitecan和trastuzumab deruxtecan僅得擇一給付\n' else '')
    else '')

//============================================
// 列出「不符合」項目判斷式 - 代碼或條件不符
//============================================

define function "不符合項目_代碼或條件不符"():
  // 主要規定一：初次使用條件 - 代碼條件不符
  (if Reusable."初次申請" and (
    not "ICD代碼檢核_布林值" or 
    not "1條件2-1=無法切除的局部晚期或轉移性的乳癌成年病人" or 
    not "1條件2-3=癌症分期分數或結果為M>=1" or
    not "1條件2-2=先前未接受過trastuzumab deruxtecan治療"
  )
    then '<主要規定一：初次使用條件>\n' +
         (if not "ICD代碼檢核_布林值" 
           then '▲ 規則1-條件2-0：主要疾病之ICD代碼未使用C50\n' else '') +
         (if not "1條件2-1=無法切除的局部晚期或轉移性的乳癌成年病人" 
           then '▲ 規則1-條件2-1：非成年患者（<18歲）\n' else '') +
         (if not "1條件2-3=癌症分期分數或結果為M>=1" 
           then '▲ 規則1-條件2-3：癌症分期分數或結果不為M≥1（非轉移性）\n' else '') +
         (if not "1條件2-2=先前未接受過trastuzumab deruxtecan治療" 
           then '▲ 規則1-條件5：先前已接受過trastuzumab deruxtecan治療\n' else '') +
         '\n'
    else '') +
  
  // 主要規定三：藥品使用規則 - 代碼條件不符
  (if not "藥品規則1=每次申請之療程以3個月為限" or not "藥品規則2=Sacituzumab govitecan和trastuzumab deruxtecan僅能擇一給付"
    then '<主要規定三：藥品使用規則>\n' +
         (if not "藥品規則1=每次申請之療程以3個月為限" 
           then '▲ 規則3-1：每次申請之療程超過3個月（84天）\n' else '') +
         (if not "藥品規則2=Sacituzumab govitecan和trastuzumab deruxtecan僅能擇一給付" 
           then '▲ 規則3-2：同時使用Sacituzumab govitecan和trastuzumab deruxtecan\n' else '')
    else '')

//============================================
// 列出「不符合」項目判斷式 - 必要資料未填寫
//============================================

define function "不符合項目_必要資料未填寫"():
  // 主要規定一：初次使用條件 - 必要資料未填寫
  (if Reusable."初次申請" and (
    not "條件1=適用於治療先前已接受兩次以上全身性治療無效" or 
    not "1條件2-2=病摘應敘明無法切除" or 
    not "1條件2-4/2條件1=ER陰性" or 
    not "1條件2-5/2條件1=PR陰性" or 
    not "1條件2-6/2條件1=HER2陰性" or 
    not "1條件3=病人身體狀況良好(ECOG≦1)" or 
    not "1條件4=須使用過taxane類藥物至少1個療程"
  )
    then '<主要規定一：初次使用條件>\n' +
         (if not "條件1=適用於治療先前已接受兩次以上全身性治療無效" 
           then '▲ 規則1-條件1：未提供先前已接受兩次以上全身性治療無效之證明\n' else '') +
         (if not "1條件2-2=病摘應敘明無法切除" 
           then '▲ 規則1-條件2-2：病摘未敘明無法切除\n' else '') +
         (if not ("1條件2-4/2條件1=ER陰性" and "1條件2-5/2條件1=PR陰性" and "1條件2-6/2條件1=HER2陰性") 
           then '▲ 規則1-條件2-4/2-5/2-6：未符合三陰性乳癌條件或檢測資料非3個月內\n' +
                (if not "1條件2-4/2條件1=ER陰性"
                  then '  - ER非陰性或未提供3個月內ER檢測資料\n' else '') +
                (if not "1條件2-5/2條件1=PR陰性"
                  then '  - PR非陰性或未提供3個月內PR檢測資料\n' else '') +
                (if not "1條件2-6/2條件1=HER2陰性"
                  then '  - HER2非陰性或未提供3個月內HER2檢測資料\n' else '')
           else '') +
         (if not "1條件3=病人身體狀況良好(ECOG≦1)" 
           then '▲ 規則1-條件3：未提供ECOG評估或ECOG>1\n' else '') +
         (if not "1條件4=須使用過taxane類藥物至少1個療程" 
           then '▲ 規則1-條件4：未提供使用過taxane類藥物之紀錄\n' else '') +
         '\n'
    else '') +
  
  // 主要規定二：續用條件 - 必要資料未填寫
  (if Reusable."續用申請" and not "規則1=再次申請必須提出客觀證據（如：影像學）證實無惡化，才可繼續使用"
    then '<主要規定二：續用條件－治療持續給付>\n' +
         '▲ 續用規則1：未提供客觀證據（如：影像學）或顯示疾病惡化\n' +
         '\n'
    else '')

//============================================
// 審核結果
//============================================

define "乳癌Sacituzumab_govitecan申請結果_布林":
  case
    when Reusable."初次申請" then (
      "條件1=適用於治療先前已接受兩次以上全身性治療無效" and
      "1條件2=無法切除的局部晚期或轉移性的三陰性乳癌成年病人" and
      "1條件3=病人身體狀況良好(ECOG≦1)" and
      "1條件4=須使用過taxane類藥物至少1個療程" and
      "1條件2-2=先前未接受過trastuzumab deruxtecan治療" and
      "藥品規則1=每次申請之療程以3個月為限" and
      "藥品規則2=Sacituzumab govitecan和trastuzumab deruxtecan僅能擇一給付"
    )
    when Reusable."續用申請" then (
      "規則1=再次申請必須提出客觀證據（如：影像學）證實無惡化，才可繼續使用" and
      "藥品規則1=每次申請之療程以3個月為限" and
      "藥品規則2=Sacituzumab govitecan和trastuzumab deruxtecan僅能擇一給付"
    )
    else false
  end

define "乳癌Sacituzumab_govitecan申請之CQL檢核結果":
  if (
    Reusable."初次申請" and 
    "條件1=適用於治療先前已接受兩次以上全身性治療無效" and
    "1條件2=無法切除的局部晚期或轉移性的三陰性乳癌成年病人" and
    "1條件3=病人身體狀況良好(ECOG≦1)" and
    "1條件4=須使用過taxane類藥物至少1個療程" and
    "1條件2-2=先前未接受過trastuzumab deruxtecan治療" and
    "藥品規則1=每次申請之療程以3個月為限" and
    "藥品規則2=Sacituzumab govitecan和trastuzumab deruxtecan僅能擇一給付"
  )
  then '✓通過：初次使用－乳癌 Sacituzumab govitecan 用藥申請'

  else if (
    Reusable."續用申請" and
    "規則1=再次申請必須提出客觀證據（如：影像學）證實無惡化，才可繼續使用" and
    "藥品規則1=每次申請之療程以3個月為限" and
    "藥品規則2=Sacituzumab govitecan和trastuzumab deruxtecan僅能擇一給付"
  )
  then '✓通過：續用－乳癌 Sacituzumab govitecan 用藥申請'
  
  else if Reusable."初次申請"
  then '✖不通過：初次使用－乳癌 Sacituzumab govitecan 用藥申請'
  
  else if Reusable."續用申請"
  then '✖不通過：續用－乳癌 Sacituzumab govitecan 用藥申請'
  
  else '✖不通過：無法判定申請類型－乳癌 Sacituzumab govitecan 用藥申請'

//============================================
// 報告總結
//============================================

define "報告總結":
  '\n=== 無法切除的局部晚期或轉移性三陰性乳癌之Sacituzumab govitecan 申請審核報告 ===\n' +
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
  "乳癌Sacituzumab_govitecan申請之CQL檢核結果" +
  '\n===============================================\n'
