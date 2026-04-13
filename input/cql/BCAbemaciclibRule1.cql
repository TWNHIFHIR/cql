//乳癌_Abemaciclib給付規定
library BCAbemaciclibRule1 version '1.0.0'

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

//條件1:Abemaciclib併用內分泌療法(tamoxifen或芳香環酶抑制劑)
define "規則1-1=Abemaciclib併用內分泌療法(tamoxifen或芳香環酶抑制劑)":
(
  // 申請期間與內分泌療法時間重疊
  Reusable."HasConcurrentMedicationOrder"(CodeConcept.L01EF03, CodeConcept."內分泌療法藥物(tamoxifen或芳香環酶抑制劑)")
  and Reusable."醫令類別為1"
)


//條件2:作為荷爾蒙受體(HR)陽性(ER或PR>30%)
//條件2-1 ER
define "規則1-2-1=檢驗檢查-作為荷爾蒙受體(HR)陽性(ER>30%)":
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
      and Cdg.code in CodeConcept.ER
    )
    and (
      (OBs.value is Quantity
        and (OBs.value as Quantity).value > 30
        and (OBs.value as Quantity).comparator = '>'
        and (OBs.value as Quantity).unit = '%')
      or (OBs.value is FHIR.string
        and Matches((OBs.value as FHIR.string).value, '.*ER>30%.*'))
    )
  )

define "規則1-2-1=基因檢測-作為荷爾蒙受體(HR)陽性(ER>30%)":
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
              and Cdg.code in CodeConcept.ER
        )
        and (
          (Comp.value is Quantity
            and (Comp.value as Quantity).value > 30
            and (Comp.value as Quantity).comparator = '>'
            and (Comp.value as Quantity).unit = '%')
          or (Comp.value is FHIR.string
            and Matches((Comp.value as FHIR.string).value, '.*ER>30%.*'))
        )
    )
  )

define "規則1-2-1=作為荷爾蒙受體(HR)陽性(ER>30%)":
  "規則1-2-1=檢驗檢查-作為荷爾蒙受體(HR)陽性(ER>30%)"
  or "規則1-2-1=基因檢測-作為荷爾蒙受體(HR)陽性(ER>30%)"

//條件2-2 PR
define "規則1-2-2=檢驗檢查-作為荷爾蒙受體(HR)陽性(PR>30%)":
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
      and Cdg.code in CodeConcept.PR
    )
    and (
      (OBs.value is Quantity
        and (OBs.value as Quantity).value > 30
        and (OBs.value as Quantity).comparator = '>'
        and (OBs.value as Quantity).unit = '%')
      or (OBs.value is FHIR.string
        and Matches((OBs.value as FHIR.string).value, '.*PR>30%.*'))
    )
  )

define "規則1-2-2=基因檢測-作為荷爾蒙受體(HR)陽性(PR>30%)":
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
              and Cdg.code in CodeConcept.PR
        )
        and (
          (Comp.value is Quantity
            and (Comp.value as Quantity).value > 30
            and (Comp.value as Quantity).comparator = '>'
            and (Comp.value as Quantity).unit = '%')
          or (Comp.value is FHIR.string
            and Matches((Comp.value as FHIR.string).value, '.*PR>30%.*'))
        )
    )
  )

define "規則1-2-2=作為荷爾蒙受體(HR)陽性(PR>30%)":
  "規則1-2-2=檢驗檢查-作為荷爾蒙受體(HR)陽性(PR>30%)"
  or "規則1-2-2=基因檢測-作為荷爾蒙受體(HR)陽性(PR>30%)"


define "規則1-2=作為荷爾蒙受體(HR)陽性(ER或PR>30%)":
"規則1-2-1=作為荷爾蒙受體(HR)陽性(ER>30%)" or "規則1-2-2=作為荷爾蒙受體(HR)陽性(PR>30%)"


//條件3:第二型人類表皮生長因子受體(HER2)陰性
define "規則1-3=檢驗檢查-第二型人類表皮生長因子受體(HER2)陰性":
  Reusable."HasHER2NegativeOrNDTest"

define "規則1-3=基因檢測-第二型人類表皮生長因子受體(HER2)陰性":
  Reusable."HasHER2NegativeOrNDGene"

define "規則1-3=第二型人類表皮生長因子受體(HER2)陰性":
  "規則1-3=檢驗檢查-第二型人類表皮生長因子受體(HER2)陰性"
  or "規則1-3=基因檢測-第二型人類表皮生長因子受體(HER2)陰性"


//條件4:淋巴結陽性

//條件4-1
define "規則1-4-1=6個月內影像報告":
  Reusable."HasRecentImageReport"("本次申請起始日期", 180)



//條件4-2
define "規則1-4-2=癌症分期分數或結果為N>=1":
  exists (
    [Observation] O
      where exists (
        O.code.coding Cdg
          where Cdg.code = '399390009'
            and Cdg in CodeConcept.SNOMED
      )
        and O.value is not null
        and O.value is FHIR.string
        and Matches((O.value as FHIR.string).value, '.*N[1-9].*')
  )


//條件4-3
define "規則1-4-3=6個月內淋巴結陽性檢查報告":
  exists (
    [DiagnosticReport] O2
    where exists (
      O2.code.coding Cdg
      where Cdg in CodeConcept.LOINC
        and Cdg.code in CodeConcept.DiagnosticReport
    )
    and O2.effective is not null
    and FHIRHelpers.ToDateTime(O2.effective) >= "本次申請起始日期" - 180 days
    and FHIRHelpers.ToDateTime(O2.effective) <= "本次申請起始日期"
    and O2.conclusion is not null
    and Matches(O2.conclusion, '(?i).*(positive|detected|present|Positive|Detected|Present|\\+).*')
  )

define "規則1-4=淋巴結陽性":
"規則1-4-1=6個月內影像報告"
and "規則1-4-2=癌症分期分數或結果為N>=1"
and "規則1-4-3=6個月內淋巴結陽性檢查報告"


//條件5:高復發風險之早期乳癌

//條件5-1
define "規則1-5-1=pALN，陽性腋下淋巴結≥4":
Reusable."ICD-10使用C50" 
and "規則1-4-1=6個月內影像報告"
and Count(
    [Observation] O
    where exists (
      O.code.coding Cdg
      where Cdg.code = '399390009'
        and Cdg in CodeConcept.SNOMED
    )
    and O.value is not null
    and O.value is FHIR.string
    and Matches((O.value as FHIR.string).value, '.*N[2-9].*') //癌症分期分數或結果為N>=2
  ) > 0


//條件5-2
define "規則1-5-2=pALN，陽性腋下淋巴結為1-3，且腫瘤大小≥5":
Reusable."ICD-10使用C50" 
and "規則1-4-1=6個月內影像報告"
and Count(
    [Observation] O
    where exists (
      O.code.coding Cdg
      where Cdg.code = '399390009'
        and Cdg in CodeConcept.SNOMED
    )
    and O.value is not null
    and O.value is FHIR.string
    and Matches((O.value as FHIR.string).value, '.*N[1-9].*')//癌症分期分數或結果為N>=1
    and Matches((O.value as FHIR.string).value, '.*T[2-9].*') //癌症分期分數或結果為T>=2
  ) > 0


//條件5-3
define "規則1-5-3=pALN，陽性腋下淋巴結為1-3，且腫瘤細胞分化第3級":
Reusable."ICD-10使用C50" 
and "規則1-4-1=6個月內影像報告"
and (Count(
    [Observation] O
    where exists (
      O.code.coding Cdg
      where Cdg.code = '399390009'
        and Cdg in CodeConcept.SNOMED
    )
    and O.value is not null
    and O.value is FHIR.string
    and Matches((O.value as FHIR.string).value, '.*N[1-9].*')//癌症分期分數或結果為N>=1
  ) > 0)
and exists (
    [DiagnosticReport] O2
    where exists (
      O2.code.coding Cdg
      where Cdg in CodeConcept.LOINC
        and Cdg.code in CodeConcept.pALNReport
    )
    and O2.effective is not null
    and FHIRHelpers.ToDateTime(O2.effective) >= "本次申請起始日期" - 180 days
    and FHIRHelpers.ToDateTime(O2.effective) <= "本次申請起始日期"
    and O2.conclusion is not null
    and Matches(O2.conclusion, '(?i).*(Grade 3|Grade3|\\+).*')
  )

define "規則1-5=高復發風險之早期乳癌":
"規則1-5-1=pALN，陽性腋下淋巴結≥4"
or "規則1-5-2=pALN，陽性腋下淋巴結為1-3，且腫瘤大小≥5"
or "規則1-5-3=pALN，陽性腋下淋巴結為1-3，且腫瘤細胞分化第3級"

//條件6
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


define "規則1-6=成年女性":
  Patient.gender = 'female'
  and "是否滿18歲"

//規則1
define "規則1":
"規則1-1=Abemaciclib併用內分泌療法(tamoxifen或芳香環酶抑制劑)"
and "規則1-2=作為荷爾蒙受體(HR)陽性(ER或PR>30%)"
and "規則1-3=第二型人類表皮生長因子受體(HER2)陰性"
and "規則1-4=淋巴結陽性"
and "規則1-5=高復發風險之早期乳癌"
and "規則1-6=成年女性"


/*規則2*/

//標準之化學及放射輔助治療藥物清單
define "規則2=使用Abemaciclib前，需接受標準之化學及放射輔助治療":
  Reusable."HasPriorMedicationUse"(CodeConcept.L01EF03, CodeConcept."標準之化學及放射輔助治療藥物")
  and Reusable."醫令類別為1"


/*規則3*/

//條件1:使用Abemaciclib前，僅能接受最多12週的內分泌治療


define "規則3-1=使用Abemaciclib前，僅能接受最多12週的內分泌治療":
  Sum(
    [MedicationRequest] MRPrior
    where (MRPrior.intent = 'plan' or MRPrior.intent = 'order')
    and (MRPrior.status is null or MRPrior.status in { 'active', 'completed' })
    // 排除本次申請的藥物
    and not exists (
      MRPrior.medication.coding Cdg
      where Cdg in CodeConcept.NHIMedication
      and Cdg.code in CodeConcept.L01EF03
    )
    // 僅計算其他內分泌治療藥物
    and exists (
      MRPrior.medication.coding Cdg
      where Cdg in CodeConcept.NHIMedication
      and Cdg.code in CodeConcept."內分泌治療藥物"
    )
    // 確保是在本次申請之前使用
    and exists MRPrior.dosageInstruction
    and MRPrior.dosageInstruction[0].timing.repeat.bounds is Period
    and (end of (MRPrior.dosageInstruction[0].timing.repeat.bounds as Period)) < "本次申請起始日期"
    return
      difference in days between
        start of (MRPrior.dosageInstruction[0].timing.repeat.bounds as Period)
      and
        end of (MRPrior.dosageInstruction[0].timing.repeat.bounds as Period)
  ) <= 84


//條件2:應於手術切除後16個月內接受本品治療
define "規則3-2=應於手術切除後16個月內接受本品治療":
  exists (
    [DiagnosticReport] O
    where exists (
      O.code.coding Cdg
      where (
        Cdg in CodeConcept.ICD10PCS2023Image
        or Cdg in CodeConcept.ICD10PCS2014Image
      )
      and Cdg.code in CodeConcept.ProcedureCodes
    )
    and O.effective is not null
    and FHIRHelpers.ToDateTime(O.effective) >= "本次申請起始日期" - 480 days
    and FHIRHelpers.ToDateTime(O.effective) <= "本次申請起始日期"
  ) 

define "規則3=使用前，僅能接受最多12週的內分泌治療，且應於手術切除後16個月內接受本品治療。":
"規則3-1=使用Abemaciclib前，僅能接受最多12週的內分泌治療"
and "規則3-2=應於手術切除後16個月內接受本品治療"

//主要規定一
define "主要規定一":
"規則1"
and "規則2=使用Abemaciclib前，需接受標準之化學及放射輔助治療"
and "規則3=使用前，僅能接受最多12週的內分泌治療，且應於手術切除後16個月內接受本品治療。"


//============================================
// 主要規定二：續用條件－治療持續給付
//============================================

//條件1:每24週須再次申請並檢附療效評估資料

// 本次申請紀錄（以最新一筆申請作為本次申請）
define "本次申請紀錄":
  Reusable."LatestMedicationPlan"(CodeConcept.L01EF03)

define "本次申請起始日期":
  Reusable."GetStartTime"("本次申請紀錄")

// 前次申請紀錄（本次申請之前最近一次的申請）
define "前次申請紀錄":
  Reusable."LatestMedicationPlanBefore"(CodeConcept.L01EF03, "本次申請起始日期")

// 檢查本次申請療程長度是否在24週內
define "規則1-1=每24週須再次申請並檢附療效評估資料":
  Reusable."醫令類別為1" 
  and Reusable."續用註記為2"
  and "本次申請紀錄" is not null
  and Reusable."HasMedicationPlanPeriodWithinDays"(CodeConcept.L01EF03, 168)


//條件2:疾病有惡化情形須停止使用

// 取得前次治療紀錄（最近一次已完成的治療）
define "前次治療紀錄":
  Reusable."LatestCompletedMedicationOrderBefore"(CodeConcept.L01EF03, "本次申請起始日期")

// 前次用藥開始日期
define "前次用藥開始日期":
  Reusable."GetStartTime"("前次治療紀錄")

// 規則1-2: 疾病有惡化情形須停止使用(續用須檢附前次治療後影像學報告)
define "規則1-2=疾病有惡化情形須停止使用":
  Reusable."HasImageReportBetweenPreviousTreatmentAndCurrentApply"(CodeConcept.L01EF03)

// 主要規定二
define "主要規定二":
Reusable."續用註記為2"
and Reusable."醫令類別為1"
and "本次申請紀錄" is not null
and "規則1-1=每24週須再次申請並檢附療效評估資料"
and "規則1-2=疾病有惡化情形須停止使用"



//============================================
// 主要規定三：藥品使用規則
//============================================

//條件1:每日至多使用2錠
define "規則1-1=每日至多使用2錠":
  Reusable."HasDailyDoseAtMost"(CodeConcept.L01EF03, 2.0, '{tbl}', 'QD')


//條件2:使用不得超過2年
define "規則1-2=使用不得超過2年":
  Reusable."HasMedicationTotalDurationWithin"(CodeConcept.L01EF03, 730)

//主要規定三
define "主要規定三":
"規則1-1=每日至多使用2錠" and "規則1-2=使用不得超過2年"


//============================================
// 列出「符合」項目判斷式
//============================================

define function "符合項目"():
  // 主要規定一：初次使用條件
  (if Reusable."初次申請" and (
    "規則1-1=Abemaciclib併用內分泌療法(tamoxifen或芳香環酶抑制劑)" or 
    "規則1-2=作為荷爾蒙受體(HR)陽性(ER或PR>30%)" or 
    "規則1-3=第二型人類表皮生長因子受體(HER2)陰性" or 
    "規則1-4=淋巴結陽性" or 
    "規則1-5=高復發風險之早期乳癌" or 
    "規則1-6=成年女性" or 
    "規則2=使用Abemaciclib前，需接受標準之化學及放射輔助治療" or 
    "規則3-1=使用Abemaciclib前，僅能接受最多12週的內分泌治療" or 
    "規則3-2=應於手術切除後16個月內接受本品治療"
  )
    then '<主要規定一：初次使用條件>\n' +
         (if "規則1-1=Abemaciclib併用內分泌療法(tamoxifen或芳香環酶抑制劑)" 
           then '● 規則1-1：Abemaciclib併用內分泌療法(tamoxifen或芳香環酶抑制劑)\n' else '') +
         (if "規則1-2-1=作為荷爾蒙受體(HR)陽性(ER>30%)" 
           then '● 規則1-2-1：荷爾蒙受體(HR)陽性(ER>30%)\n' else '') +
         (if "規則1-2-2=作為荷爾蒙受體(HR)陽性(PR>30%)" 
           then '● 規則1-2-2：荷爾蒙受體(HR)陽性(PR>30%)\n' else '') +
         (if "規則1-3=第二型人類表皮生長因子受體(HER2)陰性" 
           then '● 規則1-3：第二型人類表皮生長因子受體(HER2)陰性\n' else '') +
         (if "規則1-4-1=6個月內影像報告" 
           then '● 規則1-4-1：6個月內影像報告\n' else '') +
         (if "規則1-4-2=癌症分期分數或結果為N>=1" 
           then '● 規則1-4-2：癌症分期分數或結果為N>=1\n' else '') +
         (if "規則1-4-3=6個月內淋巴結陽性檢查報告" 
           then '● 規則1-4-3：6個月內有淋巴結陽性檢查報告\n' else '') +
         (if "規則1-5-1=pALN，陽性腋下淋巴結≥4" 
           then '● 規則1-5-1：pALN，陽性腋下淋巴結≥4\n' else '') +
         (if "規則1-5-2=pALN，陽性腋下淋巴結為1-3，且腫瘤大小≥5" 
           then '● 規則1-5-2：pALN，陽性腋下淋巴結為1-3，且腫瘤大小≥5\n' else '') +
         (if "規則1-5-3=pALN，陽性腋下淋巴結為1-3，且腫瘤細胞分化第3級" 
           then '● 規則1-5-3：pALN，陽性腋下淋巴結為1-3，且腫瘤細胞分化第3級\n' else '') +
         (if "規則1-6=成年女性" 
           then '● 規則1-6：成年女性(≥18歲)\n' else '') +
         (if "規則2=使用Abemaciclib前，需接受標準之化學及放射輔助治療" 
           then '● 規則2：使用Abemaciclib前，已接受標準之化學及放射輔助治療\n' else '') +
         (if "規則3-1=使用Abemaciclib前，僅能接受最多12週的內分泌治療" 
           then '● 規則3-1：使用Abemaciclib前，僅能接受最多12週的內分泌治療\n' else '') +
         (if "規則3-2=應於手術切除後16個月內接受本品治療" 
           then '● 規則3-2：於手術切除後16個月內接受本品治療\n' else '') +
         '\n'
    else '') +
  


  // 主要規定二：續用條件
  (if Reusable."續用申請" and (
    "規則1-1=每24週須再次申請並檢附療效評估資料" or 
    "規則1-2=疾病有惡化情形須停止使用"
  )
    then '<主要規定二：續用條件－治療持續給付>\n' +
         (if "規則1-1=每24週須再次申請並檢附療效評估資料" 
           then '● 續用規則1-1：於24週內再次申請並檢附療效評估資料\n' else '') +
         (if "規則1-2=疾病有惡化情形須停止使用" 
           then '● 續用規則1-2：已檢附前次治療後影像學報告，確認無惡化\n' else '') +
         '\n'
    else '') +
  
  // 主要規定三：藥品使用規則
  (if "規則1-1=每日至多使用2錠" or "規則1-2=使用不得超過2年"
    then '<主要規定三：藥品使用規則>\n' +
         (if "規則1-1=每日至多使用2錠" 
           then '● 規則3-1：每日劑量≤2錠\n' else '') +
         (if "規則1-2=使用不得超過2年" 
           then '● 規則3-2：使用總療程≤2年(730天)\n' else '')
    else '')

//============================================
// 列出「不符合」項目判斷式 - 代碼或條件不符
//============================================

define function "不符合項目_代碼或條件不符"():
  // 主要規定一：初次使用條件 - 代碼條件不符
  (if Reusable."初次申請" and (
    not Reusable."ICD-10使用C50" or 
    not "規則1-6=成年女性"
  )
    then '<主要規定一：初次使用條件>\n' +
         (if not Reusable."ICD-10使用C50" 
           then '▲ ICD代碼檢核：主要疾病之ICD代碼未使用C50\n' else '') +
         (if not "規則1-6=成年女性" 
           then '▲ 規則1-6：非成年女性或性別不符\n' else '') +
         '\n'
    else '') +
  
  // 主要規定三：藥品使用規則 - 代碼條件不符
  (if not "規則1-1=每日至多使用2錠" or not "規則1-2=使用不得超過2年"
    then '<主要規定三：藥品使用規則>\n' +
         (if not "規則1-1=每日至多使用2錠" 
           then '▲ 規則3-1：每日劑量超過2錠\n' else '') +
         (if not "規則1-2=使用不得超過2年" 
           then '▲ 規則3-2：使用總療程超過2年(730天)\n' else '')
    else '')

//============================================
// 列出「不符合」項目判斷式 - 必要資料未填寫
//============================================

define function "不符合項目_必要資料未填寫"():
  // 主要規定一：初次使用條件 - 必要資料未填寫
  (if Reusable."初次申請" and (
    not "規則1-1=Abemaciclib併用內分泌療法(tamoxifen或芳香環酶抑制劑)" or 
    not "規則1-2=作為荷爾蒙受體(HR)陽性(ER或PR>30%)" or 
    not "規則1-3=第二型人類表皮生長因子受體(HER2)陰性" or 
    not "規則1-4=淋巴結陽性" or 
    not "規則1-5=高復發風險之早期乳癌" or 
    not "規則2=使用Abemaciclib前，需接受標準之化學及放射輔助治療" or 
    not "規則3-1=使用Abemaciclib前，僅能接受最多12週的內分泌治療" or 
    not "規則3-2=應於手術切除後16個月內接受本品治療"
  )
    then '<主要規定一：初次使用條件>\n' +
         (if not "規則1-1=Abemaciclib併用內分泌療法(tamoxifen或芳香環酶抑制劑)" 
           then '▲ 規則1-1：未提供內分泌療法併用資料(tamoxifen或芳香環酶抑制劑)\n' else '') +
         (if not "規則1-2=作為荷爾蒙受體(HR)陽性(ER或PR>30%)" 
           then '▲ 規則1-2：未提供荷爾蒙受體(HR)檢測資料或未達陽性標準(ER或PR>30%)\n' else '') +
         (if not "規則1-3=第二型人類表皮生長因子受體(HER2)陰性" 
           then '▲ 規則1-3：未提供HER2檢測資料或HER2非陰性\n' else '') +
         (if not "規則1-4=淋巴結陽性"
           then (if not "規則1-4-1=6個月內影像報告" then '▲ 規則1-4-1：未提供6個月內影像報告\n' else '') +
                (if not "規則1-4-2=癌症分期分數或結果為N>=1" then '▲ 規則1-4-2：未提供N>=1分期資料\n' else '') +
                (if not "規則1-4-3=6個月內淋巴結陽性檢查報告" then '▲ 規則1-4-3：未提供淋巴結陽性檢查報告\n' else '')
           else '') +
         (if not "規則1-5=高復發風險之早期乳癌" 
           then '▲ 規則1-5：未符合高復發風險條件（需符合pALN相關標準之一）\n' else '') +
         (if not "規則2=使用Abemaciclib前，需接受標準之化學及放射輔助治療" 
           then '▲ 規則2：未提供標準之化學及放射輔助治療紀錄\n' else '') +
         (if not "規則3-1=使用Abemaciclib前，僅能接受最多12週的內分泌治療" 
           then '▲ 規則3-1：使用前內分泌治療超過12週\n' else '') +
         (if not "規則3-2=應於手術切除後16個月內接受本品治療" 
           then '▲ 規則3-2：未提供手術切除紀錄或超過手術切除後16個月\n' else '') +
         '\n'
    else '') +
  
  // 主要規定二：續用條件 - 必要資料未填寫
  (if Reusable."續用申請" and (
    not "規則1-1=每24週須再次申請並檢附療效評估資料" or 
    not "規則1-2=疾病有惡化情形須停止使用"
  )
    then '<主要規定二：續用條件－治療持續給付>\n' +
         (if not "規則1-1=每24週須再次申請並檢附療效評估資料" 
           then '▲ 續用規則1-1：未於24週內再次申請或未檢附療效評估資料\n' else '') +
         (if not "規則1-2=疾病有惡化情形須停止使用" 
           then '▲ 續用規則1-2：未提供前次治療後影像學報告或顯示疾病惡化\n' else '') +
         '\n'
    else '')

//============================================
// 審核結果
//============================================

define "乳癌Abemaciclib申請結果_布林":
  case
    when Reusable."初次申請" then (
      "規則1" and
      "規則2=使用Abemaciclib前，需接受標準之化學及放射輔助治療" and
      "規則3=使用前，僅能接受最多12週的內分泌治療，且應於手術切除後16個月內接受本品治療。" and
      "規則1-1=每日至多使用2錠" and
      "規則1-2=使用不得超過2年"
    )
    when Reusable."續用申請" then (
      "規則1-1=每24週須再次申請並檢附療效評估資料" and
      "規則1-2=疾病有惡化情形須停止使用" and
      "規則1-1=每日至多使用2錠" and
      "規則1-2=使用不得超過2年"
    )
    else false
  end

define "乳癌Abemaciclib申請之CQL檢核結果":
  if (
    Reusable."初次申請" and 
    "規則1" and
    "規則2=使用Abemaciclib前，需接受標準之化學及放射輔助治療" and
    "規則3=使用前，僅能接受最多12週的內分泌治療，且應於手術切除後16個月內接受本品治療。" and
    "規則1-1=每日至多使用2錠" and
    "規則1-2=使用不得超過2年"
  )
  then '✓通過：初次使用－乳癌 Abemaciclib 用藥申請'

  else if (
    Reusable."續用申請" and
    "規則1-1=每24週須再次申請並檢附療效評估資料" and
    "規則1-2=疾病有惡化情形須停止使用" and
    "規則1-1=每日至多使用2錠" and
    "規則1-2=使用不得超過2年"
  )
  then '✓通過：續用－乳癌 Abemaciclib 用藥申請'
  else if Reusable."初次申請"
  then '✖不通過：初次使用－乳癌 Abemaciclib 用藥申請'
  else if Reusable."續用申請"
  then '✖不通過：續用－乳癌 Abemaciclib 用藥申請'
  else '✖不通過：無法判定申請類型－乳癌 Abemaciclib 用藥申請'

//============================================
// 報告總結
//============================================

define "報告總結":
  '\n=== 乳癌之 Abemaciclib 申請審核報告 ===\n' +
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
  "乳癌Abemaciclib申請之CQL檢核結果" +
  '\n===============================================\n'
