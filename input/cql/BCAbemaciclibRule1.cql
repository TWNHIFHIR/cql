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

define "主要疾病ICD資料存在":
  exists (
    [Claim] C
      where exists (
        C.diagnosis D
          where D.sequence = 1
            and exists (
              D.diagnosis.coding Cdg
                where Cdg in CodeConcept.ICD10CM2023
                  or Cdg in CodeConcept.ICD10CM2014
            )
      )
  )

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
      where Reusable."IsTestObservation"(OBs)
    and exists (
      OBs.code.coding Cdg
      where Cdg in CodeConcept.LOINC
      and Cdg.code in CodeConcept.ER
    )
    and (
      (OBs.value is Quantity
        and (OBs.value as Quantity).value > 30
        and (OBs.value as Quantity).comparator = '>')
      or (OBs.value is FHIR.string
        and Matches((OBs.value as FHIR.string).value, '.*ER>30%.*'))
    )
  )

define "規則1-2-1=基因檢測-作為荷爾蒙受體(HR)陽性(ER>30%)":
  exists (
    [Observation] OBs
      where Reusable."IsGeneInfoObservation"(OBs)
    and Reusable."IsGenePanelObservation"(OBs)
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

define "規則1-2-1=有填ER檢測資料":
  exists (
    [Observation] OBs
      where Reusable."IsTestObservation"(OBs)
        and exists (
          OBs.code.coding Cdg
            where Cdg in CodeConcept.LOINC
              and Cdg.code in CodeConcept.ER
        )
        and OBs.value is not null
  )
  or exists (
    [Observation] OBs
      where Reusable."IsGeneInfoObservation"(OBs)
        and Reusable."IsGenePanelObservation"(OBs)
        and exists (
          OBs.component Comp
            where exists (
              Comp.code.coding Cdg
                where Cdg in CodeConcept.LOINC
                  and Cdg.code in CodeConcept.ER
            )
            and Comp.value is not null
        )
  )

//條件2-2 PR
define "規則1-2-2=檢驗檢查-作為荷爾蒙受體(HR)陽性(PR>30%)":
  exists (
    [Observation] OBs
      where Reusable."IsTestObservation"(OBs)
    and exists (
      OBs.code.coding Cdg
      where Cdg in CodeConcept.LOINC
      and Cdg.code in CodeConcept.PR
    )
    and (
      (OBs.value is Quantity
        and (OBs.value as Quantity).value > 30
        and (OBs.value as Quantity).comparator = '>')
      or (OBs.value is FHIR.string
        and Matches((OBs.value as FHIR.string).value, '.*PR>30%.*'))
    )
  )

define "規則1-2-2=基因檢測-作為荷爾蒙受體(HR)陽性(PR>30%)":
  exists (
    [Observation] OBs
      where Reusable."IsGeneInfoObservation"(OBs)
    and Reusable."IsGenePanelObservation"(OBs)
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

define "規則1-2-2=有填PR檢測資料":
  exists (
    [Observation] OBs
      where Reusable."IsTestObservation"(OBs)
        and exists (
          OBs.code.coding Cdg
            where Cdg in CodeConcept.LOINC
              and Cdg.code in CodeConcept.PR
        )
        and OBs.value is not null
  )
  or exists (
    [Observation] OBs
      where Reusable."IsGeneInfoObservation"(OBs)
        and Reusable."IsGenePanelObservation"(OBs)
        and exists (
          OBs.component Comp
            where exists (
              Comp.code.coding Cdg
                where Cdg in CodeConcept.LOINC
                  and Cdg.code in CodeConcept.PR
            )
            and Comp.value is not null
        )
  )


define "規則1-2=作為荷爾蒙受體(HR)陽性(ER或PR>30%)":
"規則1-2-1=作為荷爾蒙受體(HR)陽性(ER>30%)" or "規則1-2-2=作為荷爾蒙受體(HR)陽性(PR>30%)"

define "規則1-2=有填荷爾蒙受體(HR)檢測資料":
  "規則1-2-1=有填ER檢測資料"
  or "規則1-2-2=有填PR檢測資料"


//條件3:第二型人類表皮生長因子受體(HER2)陰性
define "規則1-3=檢驗檢查-第二型人類表皮生長因子受體(HER2)陰性":
  Reusable."HasHER2NegativeOrNDTest"

define "規則1-3=基因檢測-第二型人類表皮生長因子受體(HER2)陰性":
  Reusable."HasHER2NegativeOrNDGene"

define "規則1-3=第二型人類表皮生長因子受體(HER2)陰性":
  "規則1-3=檢驗檢查-第二型人類表皮生長因子受體(HER2)陰性"
  or "規則1-3=基因檢測-第二型人類表皮生長因子受體(HER2)陰性"

define "規則1-3=有填HER2檢測資料":
  exists (
    [Observation] OBs
      where Reusable."IsTestObservation"(OBs)
        and exists (
          OBs.code.coding Cdg
            where Cdg in CodeConcept.LOINC
              and Cdg.code in CodeConcept.HER2
        )
        and (
          OBs.value is not null
          or exists (OBs.interpretation I where I is not null)
        )
  )
  or exists (
    [Observation] OBs
      where Reusable."IsGeneInfoObservation"(OBs)
        and Reusable."IsGenePanelObservation"(OBs)
        and exists (
          OBs.component Comp
            where exists (
              Comp.code.coding Cdg
                where Cdg in CodeConcept.LOINC
                  and Cdg.code in CodeConcept.HER2
            )
            and (
              Comp.value is not null
            )
        )
  )


//條件4:淋巴結陽性

//條件4-1
define "規則1-4-1=6個月內影像報告":
  Reusable."HasRecentImageReport"("本次申請起始日期", 180)

define "規則1-4-1=有填影像報告資料":
  exists (
    [DiagnosticReport] Report
    where Report.effective is not null
      and (
        Reusable."IsImageReport"(Report)
        or Reusable."IsReportWithinDaysBefore"(Report, "本次申請起始日期", 180)
      )
  )



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

define "規則1-4-2=有填癌症分期資料":
  exists (
    [Observation] O
      where exists (
        O.code.coding Cdg
          where Cdg.code = '399390009'
            and Cdg in CodeConcept.SNOMED
      )
        and O.value is not null
        and O.value is FHIR.string
  )


//條件4-3
define "規則1-4-3=6個月內淋巴結陽性檢查報告":
  exists (
    [DiagnosticReport] O2
    where exists (
      O2.code.coding Cdg
      where Cdg in CodeConcept.LOINC
        and Cdg.code in CodeConcept.DiagnosticReportCode
    )
    and O2.effective is not null
    and FHIRHelpers.ToDateTime(O2.effective) >= "本次申請起始日期" - 180 days
    and FHIRHelpers.ToDateTime(O2.effective) <= "本次申請起始日期"
    and O2.conclusion is not null
    and Matches(O2.conclusion, '(?i).*(positive|detected|present|Positive|Detected|Present|\\+).*')
  )

define "規則1-4-3=有填6個月內淋巴結檢查報告":
  exists (
    [DiagnosticReport] O2
    where exists (
      O2.code.coding Cdg
      where Cdg in CodeConcept.LOINC
        and Cdg.code in CodeConcept.DiagnosticReportCode
    )
    and O2.effective is not null
    and FHIRHelpers.ToDateTime(O2.effective) >= "本次申請起始日期" - 180 days
    and FHIRHelpers.ToDateTime(O2.effective) <= "本次申請起始日期"
    and O2.conclusion is not null
  )

define "規則1-4-3=有填淋巴結檢查報告資料":
  exists (
    [DiagnosticReport] O2
    where O2.effective is not null
      and O2.conclusion is not null
      and (
        exists (
          O2.code.coding Cdg
          where Cdg in CodeConcept.LOINC
            and Cdg.code in CodeConcept.DiagnosticReportCode
        )
        or Reusable."IsReportWithinDaysBefore"(O2, "本次申請起始日期", 90)
      )
  )

define "規則1-4=淋巴結陽性":
"規則1-4-1=6個月內影像報告"
and "規則1-4-2=癌症分期分數或結果為N>=1"
and "規則1-4-3=6個月內淋巴結陽性檢查報告"

define "規則1-4=淋巴結相關必要資料存在":
  "規則1-4-1=有填影像報告資料"
  and "規則1-4-2=有填癌症分期資料"
  and "規則1-4-3=有填淋巴結檢查報告資料"


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
    and FHIRHelpers.ToDateTime(O2.effective) >= "本次申請起始日期" - 90 days
    and FHIRHelpers.ToDateTime(O2.effective) <= "本次申請起始日期"
    and O2.conclusion is not null
    and Matches(O2.conclusion, '(?i).*(Grade 3|Grade3|\\+).*')
  )

define "規則1-5=高復發風險之早期乳癌":
"規則1-5-1=pALN，陽性腋下淋巴結≥4"
or "規則1-5-2=pALN，陽性腋下淋巴結為1-3，且腫瘤大小≥5"
or "規則1-5-3=pALN，陽性腋下淋巴結為1-3，且腫瘤細胞分化第3級"

define "規則1-5=高復發風險判斷資料存在":
  "規則1-4-1=有填影像報告資料"
  and "規則1-4-2=有填癌症分期資料"

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

define "規則1-6=性別與年齡資料存在":
  Patient.gender is not null
  and Patient.birthDate is not null
  and "年齡計算用申請日期" is not null

//規則1
define "規則1":
"規則1-1=Abemaciclib併用內分泌療法(tamoxifen或芳香環酶抑制劑)"
and "規則1-2=作為荷爾蒙受體(HR)陽性(ER或PR>30%)"
and "規則1-3=第二型人類表皮生長因子受體(HER2)陰性"
and "規則1-4=淋巴結陽性"
and "規則1-5=高復發風險之早期乳癌"
and "規則1-6=成年女性"

define "有Abemaciclib申請醫令":
  exists (
    [MedicationRequest] MR
      where Reusable."IsMedicationPlan"(MR, CodeConcept.L01EF03)
  )

define "有內分泌療法醫令":
  Reusable."HasMedicationUse"(CodeConcept."內分泌療法藥物(tamoxifen或芳香環酶抑制劑)")

define "規則1-1=Abemaciclib併用內分泌療法資料存在":
  "有Abemaciclib申請醫令"
  and "有內分泌療法醫令"


/*規則2*/

//標準之化學及放射輔助治療藥物清單
define "規則2=使用Abemaciclib前，需接受標準之化學及放射輔助治療":
  Reusable."HasPriorMedicationUse"(CodeConcept.L01EF03, CodeConcept."標準之化學及放射輔助治療藥物")
  and Reusable."醫令類別為1"

define "規則2=標準化學及放射輔助治療資料存在":
  "有Abemaciclib申請醫令"
  and Reusable."HasMedicationUse"(CodeConcept."標準之化學及放射輔助治療藥物")


/*規則3*/

//條件1:使用Abemaciclib前，僅能接受最多12週的內分泌治療


define "規則3-1=使用Abemaciclib前，僅能接受最多12週的內分泌治療":
  Sum(
    [MedicationRequest] MRPrior
    where (MRPrior.intent = 'plan' or MRPrior.intent = 'order')
    and (MRPrior.status is null or MRPrior.status in { 'active', 'completed' })
    // 排除本次申請的藥物
    and not Reusable."HasMedicationCode"(MRPrior, CodeConcept.L01EF03)
    // 僅計算其他內分泌治療藥物
    and Reusable."HasMedicationCode"(MRPrior, CodeConcept."內分泌治療藥物")
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

define "規則3-1=使用前內分泌治療資料存在":
  exists (
    [MedicationRequest] MRPrior
    where (MRPrior.intent = 'plan' or MRPrior.intent = 'order')
      and (MRPrior.status is null or MRPrior.status in { 'active', 'completed' })
      and not Reusable."HasMedicationCode"(MRPrior, CodeConcept.L01EF03)
      and Reusable."HasMedicationCode"(MRPrior, CodeConcept."內分泌治療藥物")
      and exists MRPrior.dosageInstruction
      and MRPrior.dosageInstruction[0].timing.repeat.bounds is Period
      and (end of (MRPrior.dosageInstruction[0].timing.repeat.bounds as Period)) < "本次申請起始日期"
  )


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

define "規則3-2=有填手術切除紀錄":
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

define "規則3-1=每日劑量資料存在":
  exists (
    [MedicationRequest] MR
    where Reusable."IsMedicationPlan"(MR, CodeConcept.L01EF03)
      and exists (
        MR.dosageInstruction DI
        where exists (
          DI.timing.code.coding C
          where C.code = 'QD'
        )
        and exists (
          DI.doseAndRate DR
          where (DR.dose as FHIR.SimpleQuantity) is not null
            and (DR.dose as FHIR.SimpleQuantity).value is not null
            and (DR.dose as FHIR.SimpleQuantity).code = '{tbl}'
        )
      )
  )


//條件2:使用不得超過2年
define "規則1-2=使用不得超過2年":
  Reusable."HasMedicationTotalDurationWithin"(CodeConcept.L01EF03, 730)

define "規則3-2=療程期間資料存在":
  exists (
    [MedicationRequest] MR
    where MR.intent = 'plan'
      and (MR.status is null or MR.status in { 'active', 'completed', 'on-hold' })
      and Reusable."HasMedicationCode"(MR, CodeConcept.L01EF03)
      and Reusable."HasValidTiming"(MR)
  )

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
           then '● 1規則1-1：Abemaciclib併用內分泌療法(tamoxifen或芳香環酶抑制劑)\n' else '') +
         (if "規則1-2-1=作為荷爾蒙受體(HR)陽性(ER>30%)" 
           then '● 1規則1-2-1：荷爾蒙受體(HR)陽性(ER>30%)\n' else '') +
         (if "規則1-2-2=作為荷爾蒙受體(HR)陽性(PR>30%)" 
           then '● 1規則1-2-2：荷爾蒙受體(HR)陽性(PR>30%)\n' else '') +
         (if "規則1-3=第二型人類表皮生長因子受體(HER2)陰性" 
           then '● 1規則1-3：第二型人類表皮生長因子受體(HER2)陰性\n' else '') +
         (if "規則1-4-1=6個月內影像報告" 
           then '● 1規則1-4-1：3個月內影像報告\n' else '') +
         (if "規則1-4-2=癌症分期分數或結果為N>=1" 
           then '● 1規則1-4-2：癌症分期分數或結果為N>=1\n' else '') +
         (if "規則1-4-3=6個月內淋巴結陽性檢查報告" 
           then '● 1規則1-4-3：3個月內有淋巴結陽性檢查報告\n' else '') +
         (if "規則1-5-1=pALN，陽性腋下淋巴結≥4" 
           then '● 1規則1-5-1：pALN，陽性腋下淋巴結≥4\n' else '') +
         (if "規則1-5-2=pALN，陽性腋下淋巴結為1-3，且腫瘤大小≥5" 
           then '● 1規則1-5-2：pALN，陽性腋下淋巴結為1-3，且腫瘤大小≥5\n' else '') +
         (if "規則1-5-3=pALN，陽性腋下淋巴結為1-3，且腫瘤細胞分化第3級" 
           then '● 1規則1-5-3：pALN，陽性腋下淋巴結為1-3，且腫瘤細胞分化第3級\n' else '') +
         (if "規則1-6=成年女性" 
           then '● 1規則1-6：成年女性(≥18歲)\n' else '') +
         (if "規則2=使用Abemaciclib前，需接受標準之化學及放射輔助治療" 
           then '● 1規則2：使用Abemaciclib前，已接受標準之化學及放射輔助治療\n' else '') +
         (if "規則3-1=使用Abemaciclib前，僅能接受最多12週的內分泌治療" 
           then '● 1規則3-1：使用Abemaciclib前，僅能接受最多12週的內分泌治療\n' else '') +
         (if "規則3-2=應於手術切除後16個月內接受本品治療" 
           then '● 1規則3-2：於手術切除後16個月內接受本品治療\n' else '') +
         '\n'
    else '') +
  


  // 主要規定二：續用條件
  (if Reusable."續用申請" and (
    "規則1-1=每24週須再次申請並檢附療效評估資料" or 
    "規則1-2=疾病有惡化情形須停止使用"
  )
    then '<主要規定二：續用條件－治療持續給付>\n' +
         (if "規則1-1=每24週須再次申請並檢附療效評估資料" 
           then '● 2規則1-1：於24週內再次申請並檢附療效評估資料\n' else '') +
         (if "規則1-2=疾病有惡化情形須停止使用" 
           then '● 2規則1-2：已檢附前次治療後影像學報告，確認無惡化\n' else '') +
         '\n'
    else '') +
  
  // 主要規定三：藥品使用規則
  (if "規則1-1=每日至多使用2錠" or "規則1-2=使用不得超過2年"
    then '<主要規定三：藥品使用規則>\n' +
         (if "規則1-1=每日至多使用2錠" 
           then '● 3規則1：每日劑量≤2錠\n' else '') +
         (if "規則1-2=使用不得超過2年" 
           then '● 3規則2：使用總療程≤2年(730天)\n' else '')
    else '')

//============================================
// 列出「不符合」項目判斷式 - 條件或代碼不符合
//============================================

define function "不符合項目_條件或代碼不符合"():
  // 主要規定一：初次使用條件 - 資料已填但條件或代碼不符合
  (if Reusable."初次申請" and (
    ("主要疾病ICD資料存在" and not Reusable."ICD-10使用C50") or
    ("規則1-1=Abemaciclib併用內分泌療法資料存在" and not "規則1-1=Abemaciclib併用內分泌療法(tamoxifen或芳香環酶抑制劑)") or
    ("規則1-2=有填荷爾蒙受體(HR)檢測資料" and not "規則1-2=作為荷爾蒙受體(HR)陽性(ER或PR>30%)") or
    ("規則1-3=有填HER2檢測資料" and not "規則1-3=第二型人類表皮生長因子受體(HER2)陰性") or
    ("規則1-4-1=有填影像報告資料" and not "規則1-4-1=6個月內影像報告") or
    ("規則1-4-2=有填癌症分期資料" and not "規則1-4-2=癌症分期分數或結果為N>=1") or
    ("規則1-4-3=有填淋巴結檢查報告資料" and not "規則1-4-3=6個月內淋巴結陽性檢查報告") or
    ("規則1-5=高復發風險判斷資料存在" and not "規則1-5=高復發風險之早期乳癌") or
    ("規則1-6=性別與年齡資料存在" and not "規則1-6=成年女性") or
    ("規則2=標準化學及放射輔助治療資料存在" and not "規則2=使用Abemaciclib前，需接受標準之化學及放射輔助治療") or
    ("規則3-1=使用前內分泌治療資料存在" and not "規則3-1=使用Abemaciclib前，僅能接受最多12週的內分泌治療") or
    ("規則3-2=有填手術切除紀錄" and not "規則3-2=應於手術切除後16個月內接受本品治療")
  )
    then '<主要規定一：初次使用條件>\n' +
         (if "主要疾病ICD資料存在" and not Reusable."ICD-10使用C50"
           then '▲ 1條件ICD代碼檢核：主要疾病之ICD代碼未使用C50\n' else '') +
         (if "規則1-1=Abemaciclib併用內分泌療法資料存在" and not "規則1-1=Abemaciclib併用內分泌療法(tamoxifen或芳香環酶抑制劑)"
           then '▲ 1規則1-1：Abemaciclib與內分泌療法醫令期間未重疊或醫令類別不符\n' else '') +
         (if "規則1-2=有填荷爾蒙受體(HR)檢測資料" and not "規則1-2=作為荷爾蒙受體(HR)陽性(ER或PR>30%)"
           then '▲ 1規則1-2：荷爾蒙受體(HR)未達陽性標準(ER或PR>30%)\n' else '') +
         (if "規則1-3=有填HER2檢測資料" and not "規則1-3=第二型人類表皮生長因子受體(HER2)陰性"
           then '▲ 1規則1-3：HER2檢測結果非陰性或非ND\n' else '') +
         (if "規則1-4-1=有填影像報告資料" and not "規則1-4-1=6個月內影像報告"
           then '▲ 1規則1-4-1：未符合「三個月內且代碼正確」之影像或檢查報告條件\n' else '') +
         (if "規則1-4-2=有填癌症分期資料" and not "規則1-4-2=癌症分期分數或結果為N>=1"
           then '▲ 1規則1-4-2：癌症分期未達N>=1\n' else '') +
         (if "規則1-4-3=有填淋巴結檢查報告資料" and not "規則1-4-3=6個月內淋巴結陽性檢查報告"
           then '▲ 1規則1-4-3：未符合「三個月內且代碼正確」之影像或檢查報告條件\n' else '') +
         (if "規則1-5=高復發風險判斷資料存在" and not "規則1-5=高復發風險之早期乳癌"
           then '▲ 1規則1-5：未符合高復發風險條件（需符合pALN相關標準之一）\n' else '') +
         (if "規則1-6=性別與年齡資料存在" and not "規則1-6=成年女性"
           then '▲ 1規則1-6：非成年女性或性別不符\n' else '') +
         (if "規則2=標準化學及放射輔助治療資料存在" and not "規則2=使用Abemaciclib前，需接受標準之化學及放射輔助治療"
           then '▲ 1規則2：標準之化學及放射輔助治療未早於本次Abemaciclib申請或醫令類別不符\n' else '') +
         (if "規則3-1=使用前內分泌治療資料存在" and not "規則3-1=使用Abemaciclib前，僅能接受最多12週的內分泌治療"
           then '▲ 1規則3-1：使用Abemaciclib前內分泌治療超過12週\n' else '') +
         (if "規則3-2=有填手術切除紀錄" and not "規則3-2=應於手術切除後16個月內接受本品治療"
           then '▲ 1規則3-2：超過手術切除後16個月才接受本品治療\n' else '') +
         '\n'
    else '') +
  
  // 主要規定三：藥品使用規則 - 資料已填但條件或代碼不符合
  (if ("規則3-1=每日劑量資料存在" and not "規則1-1=每日至多使用2錠")
    or ("規則3-2=療程期間資料存在" and not "規則1-2=使用不得超過2年")
    then '<主要規定三：藥品使用規則>\n' +
         (if "規則3-1=每日劑量資料存在" and not "規則1-1=每日至多使用2錠"
           then '▲ 3規則1：每日劑量超過2錠\n' else '') +
         (if "規則3-2=療程期間資料存在" and not "規則1-2=使用不得超過2年"
           then '▲ 3規則2：使用總療程超過2年(730天)\n' else '')
    else '')

//============================================
// 列出「不符合」項目判斷式 - 必要資料未填寫
//============================================

define function "不符合項目_必要資料未填寫"():
  // 主要規定一：初次使用條件 - 必要資料未填寫
  (if Reusable."初次申請" and (
    not "主要疾病ICD資料存在" or
    not "規則1-1=Abemaciclib併用內分泌療法資料存在" or
    not "規則1-2=有填荷爾蒙受體(HR)檢測資料" or
    not "規則1-3=有填HER2檢測資料" or
    not "規則1-4-1=有填影像報告資料" or
    not "規則1-4-2=有填癌症分期資料" or
    not "規則1-4-3=有填淋巴結檢查報告資料" or
    not "規則1-6=性別與年齡資料存在" or
    not "規則2=標準化學及放射輔助治療資料存在" or
    not "規則3-1=使用前內分泌治療資料存在" or
    not "規則3-2=有填手術切除紀錄"
  )
    then '<主要規定一：初次使用條件>\n' +
         (if not "主要疾病ICD資料存在"
           then '▲ 1條件ICD代碼檢核：未提供主要疾病ICD診斷資料\n' else '') +
         (if not "規則1-1=Abemaciclib併用內分泌療法資料存在"
           then '▲ 1規則1-1：未提供Abemaciclib申請醫令或內分泌療法醫令資料(tamoxifen或芳香環酶抑制劑)\n' else '') +
         (if not "規則1-2=有填荷爾蒙受體(HR)檢測資料"
           then '▲ 1規則1-2：未提供荷爾蒙受體(HR)檢測資料(ER或PR)\n' else '') +
         (if not "規則1-3=有填HER2檢測資料"
           then '▲ 1規則1-3：未提供HER2檢測資料\n' else '') +
         (if not "規則1-4-1=有填影像報告資料"
           then '▲ 1規則1-4-1：未提供影像報告資料\n' else '') +
         (if not "規則1-4-2=有填癌症分期資料"
           then '▲ 1規則1-4-2：未提供癌症分期分數或結果資料\n' else '') +
         (if not "規則1-4-3=有填淋巴結檢查報告資料"
           then '▲ 1規則1-4-3：未提供淋巴結檢查報告資料\n' else '') +
         (if not "規則1-6=性別與年齡資料存在"
           then '▲ 1規則1-6：未提供性別、出生日期或本次申請日期資料\n' else '') +
         (if not "規則2=標準化學及放射輔助治療資料存在"
           then '▲ 1規則2：未提供標準之化學及放射輔助治療紀錄\n' else '') +
         (if not "規則3-1=使用前內分泌治療資料存在"
           then '▲ 1規則3-1：未提供使用Abemaciclib前內分泌治療紀錄\n' else '') +
         (if not "規則3-2=有填手術切除紀錄"
           then '▲ 1規則3-2：未提供手術切除紀錄\n' else '') +
         '\n'
    else '') +
  
  // 主要規定二：續用條件 - 必要資料未填寫
  (if Reusable."續用申請" and (
    not "規則1-1=每24週須再次申請並檢附療效評估資料" or 
    not "規則1-2=疾病有惡化情形須停止使用"
  )
    then '<主要規定二：續用條件－治療持續給付>\n' +
         (if not "規則1-1=每24週須再次申請並檢附療效評估資料" 
           then '▲ 2規則1-1：未於24週內再次申請或未檢附療效評估資料\n' else '') +
         (if not "規則1-2=疾病有惡化情形須停止使用" 
           then '▲ 2規則1-2：未提供前次治療後影像學報告資料\n' else '') +
         '\n'
    else '') +

  // 主要規定三：藥品使用規則 - 必要資料未填寫
  (if (not "規則3-1=每日劑量資料存在" or not "規則3-2=療程期間資料存在")
    then '<主要規定三：藥品使用規則>\n' +
         (if not "規則3-1=每日劑量資料存在"
           then '▲ 3規則1：未提供每日劑量資料\n' else '') +
         (if not "規則3-2=療程期間資料存在"
           then '▲ 3規則2：未提供療程起迄日期資料\n' else '') +
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
  '\n【▲不符合項目 - 必要資料未填寫】\n' +
  (if "不符合項目_必要資料未填寫"() = '' then '無\n' else "不符合項目_必要資料未填寫"()) +
  '\n【▲不符合項目 - 條件或代碼不符合】\n' +
  (if "不符合項目_條件或代碼不符合"() = '' then '無\n' else "不符合項目_條件或代碼不符合"()) +
  '\n【申請結果】\n' +
  "乳癌Abemaciclib申請之CQL檢核結果" +
  '\n===============================================\n'
