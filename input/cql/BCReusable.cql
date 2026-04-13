library BCReusable version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

include BCCodeConcept version '1.0.0' called CodeConcept

context Patient

//乳癌疾病代碼：ICD-10-CM = C50
define "ICD-10使用C50":
  exists (
    [Claim] C
      where exists (
        C.diagnosis D
          where D.sequence = 1
            and exists ( 
              D.diagnosis.coding Cdg
                where (
                  Cdg in CodeConcept.ICD10CM2023
                  or Cdg in CodeConcept.ICD10CM2014
                )
                and Substring(Cdg.code, 0, 3) in CodeConcept.ICDBC
            )
      )
  )

//乳癌疾病之腫瘤代碼：ICD-10-CM = C77、C78、C79
define "ICD-10使用C77、C78、C79":
  exists (
    [Claim] C
      where exists (
        C.diagnosis D
          where D.sequence = 1
            and exists ( 
              D.diagnosis.coding Cdg
                where (
                  Cdg in CodeConcept.ICD10CM2023
                  or Cdg in CodeConcept.ICD10CM2014
                )
              and Substring(Cdg.code, 0, 3) in CodeConcept.ICDBCandTumor
          )
      )
  )


//乳癌疾病之腫瘤代碼：ICD-10-CM = C77、C78、C79但排除C79.3
define "ICD-10使用C77、C78、C79但排除C79.3":
  exists (
    [Claim] C
    where exists (
      C.diagnosis D
      where exists ( 
        D.diagnosis.coding Cdg
        where (
          Cdg in CodeConcept.ICD10CM2023
          or Cdg in CodeConcept.ICD10CM2014
        )
        and (
          (Substring(Cdg.code, 0, 3) in { 'C77', 'C78' })
          or (Substring(Cdg.code, 0, 3) = 'C79' and Cdg.code != 'C79.3')
        )
      )
    )
  )


//續用判斷
define "續用註記為1":
  exists (
    [Claim] C
      where exists (
        C.item I
          where exists (
            I.modifier M
                where exists (
                  M.coding Cdg
                         where Cdg in CodeConcept.NHIContinuationStatus
                         and Cdg.code in CodeConcept."續用註記為1"
                  )
          )
      )
  )


//續用判斷
define "續用註記為2":
  exists (
    [Claim] C
      where exists (
        C.item I
          where exists (
            I.modifier M
                where exists (
                  M.coding Cdg
                         where Cdg in CodeConcept.NHIContinuationStatus
                         and Cdg.code in CodeConcept."續用註記為2"
                  )
          )
      )
  )

//申請類型判斷
define "申請類型":
  case
    when "續用註記為1" then '初次使用'
    when "續用註記為2" then '續用'
    else '無法判斷申請類型'
  end

define "初次申請":
  "申請類型" = '初次使用'

define "續用申請":
  "申請類型" = '續用'

define "申請類型未知":
  "申請類型" = '無法判斷申請類型'

//用藥線別不為1
define "用藥線別≠1":
  exists (
    [Claim] C
      where exists (
        C.item I
          where exists (
            I.modifier M
              where exists (
                M.coding Cdg
                  where Cdg in CodeConcept.NHILOT
                    and Cdg.code != '1'
              )
          )
      )
  )


//用藥線別為2
define "用藥線別=2":
  exists (
    [Claim] C
      where exists (
        C.item I
          where exists (
            I.modifier M
              where exists (
                M.coding Cdg
                  where Cdg in CodeConcept.NHILOT
                    and Cdg.code = '2'
              )
          )
      )
  )

//用藥線別為1
define "用藥線別=1":
  exists (
    [Claim] C
      where exists (
        C.item I
          where exists (
            I.modifier M
              where exists (
                M.coding Cdg
                  where Cdg in CodeConcept.NHILOT
                    and Cdg.code = '1'
              )
          )
      )
  )


// 醫令類別=1 (orderType = '1')
define "醫令類別為1":
 exists (
    [Claim] C
      where exists (
        C.item I
          where exists (
            I.productOrService.coding PSC
              where PSC in CodeConcept.NHIOrderType
              and PSC.code in CodeConcept."醫令類別"
          )
      )
  )

//影像報告
define function "IsImageReport"(Report DiagnosticReport):
  exists (
    Report.code.coding Cdg
    where (
      Cdg in CodeConcept.ICD10PCS2023Image
      or Cdg in CodeConcept.ICD10PCS2014Image
    )
    and Cdg.code in CodeConcept.ImageCodes
  )

//分子/病理檢查報告
define function "IsMolecularReport"(Report DiagnosticReport):
  exists (
    Report.code.coding Cdg
    where Cdg in CodeConcept.LOINC
      and Cdg.code in CodeConcept.MolecularReport
  )

//報告日期是否落在參考日期前指定天數內
define function "IsReportWithinDaysBefore"(Report DiagnosticReport, ReferenceDate DateTime, LookbackDays Integer):
  Report.effective is not null
  and ReferenceDate is not null
  and FHIRHelpers.ToDateTime(Report.effective) <= ReferenceDate
  and (duration in days between FHIRHelpers.ToDateTime(Report.effective) and ReferenceDate) <= LookbackDays

define function "HasRecentImageReport"(ReferenceDate DateTime, LookbackDays Integer):
  exists (
    [DiagnosticReport] Report
    where "IsImageReport"(Report)
      and "IsReportWithinDaysBefore"(Report, ReferenceDate, LookbackDays)
  )

define function "HasRecentMolecularReport"(ReferenceDate DateTime, LookbackDays Integer):
  exists (
    [DiagnosticReport] Report
    where "IsMolecularReport"(Report)
      and "IsReportWithinDaysBefore"(Report, ReferenceDate, LookbackDays)
  )

define function "IsTestObservation"(OBs Observation):
  exists (
    OBs.category C
      where exists (
        C.coding Cdg
          where Cdg in CodeConcept.NHIPASSupportingInfoType
            and Cdg.code = 'tests'
      )
  )

define function "IsGeneInfoObservation"(OBs Observation):
  exists (
    OBs.category C
      where exists (
        C.coding Cdg
          where Cdg in CodeConcept.NHIPASSupportingInfoType
            and Cdg.code = 'geneInfo'
      )
  )

define function "IsGenePanelObservation"(OBs Observation):
  exists (
    OBs.code.coding Cdg
      where Cdg in CodeConcept.LOINC
        and Cdg.code = '69548-6'
  )

define function "HasTestObservationWithInterpretationAndValuePattern"(MarkerCodes List<String>, InterpretationCodes List<String>, ValuePattern String):
  exists (
    [Observation] OBs
      where "IsTestObservation"(OBs)
        and exists (
          OBs.code.coding Cdg
            where Cdg in CodeConcept.LOINC
              and Cdg.code in MarkerCodes
        )
        and exists (
          OBs.interpretation.coding INT
            where INT in CodeConcept.InterpretationCodes
              and INT.code in InterpretationCodes
        )
        and OBs.value is string
        and Matches(OBs.value as string, ValuePattern)
  )

define function "HasGeneInfoObservationWithInterpretationAndTextPattern"(MarkerCodes List<String>, InterpretationCodes List<String>, TextPattern String):
  exists (
    [Observation] OBs
      where "IsGeneInfoObservation"(OBs)
        and "IsGenePanelObservation"(OBs)
        and exists (
          OBs.component Comp
            where exists (
              Comp.code.coding Cdg
                where Cdg in CodeConcept.LOINC
                  and Cdg.code in MarkerCodes
            )
              and exists (
                Comp.interpretation.coding INT
                  where INT in CodeConcept.InterpretationCodes
                    and INT.code in InterpretationCodes
              )
              and exists (
                Comp.interpretation I
                  where Matches(I.text, TextPattern)
              )
        )
  )

define function "HasTestObservationWithInterpretationCodes"(MarkerCodes List<String>, InterpretationCodes List<String>):
  exists (
    [Observation] OBs
      where "IsTestObservation"(OBs)
        and exists (
          OBs.code.coding Cdg
            where Cdg in CodeConcept.LOINC
              and Cdg.code in MarkerCodes
        )
        and exists (
          OBs.interpretation.coding INT
            where INT in CodeConcept.InterpretationCodes
              and INT.code in InterpretationCodes
        )
  )

define function "HasGeneInfoObservationWithInterpretationCodes"(MarkerCodes List<String>, InterpretationCodes List<String>):
  exists (
    [Observation] OBs
      where "IsGeneInfoObservation"(OBs)
        and "IsGenePanelObservation"(OBs)
        and exists (
          OBs.component Comp
            where exists (
              Comp.code.coding Cdg
                where Cdg in CodeConcept.LOINC
                  and Cdg.code in MarkerCodes
            )
              and exists (
                Comp.interpretation.coding INT
                  where INT in CodeConcept.InterpretationCodes
                    and INT.code in InterpretationCodes
              )
        )
  )

define function "HasTestObservationWithValuePattern"(MarkerCodes List<String>, ValuePattern String):
  exists (
    [Observation] OBs
      where "IsTestObservation"(OBs)
        and exists (
          OBs.code.coding Cdg
            where Cdg in CodeConcept.LOINC
              and Cdg.code in MarkerCodes
        )
        and OBs.value is string
        and Matches(OBs.value as string, ValuePattern)
  )

define function "HasGeneInfoObservationWithTextPattern"(MarkerCodes List<String>, TextPattern String):
  exists (
    [Observation] OBs
      where "IsGeneInfoObservation"(OBs)
        and "IsGenePanelObservation"(OBs)
        and exists (
          OBs.component Comp
            where exists (
              Comp.code.coding Cdg
                where Cdg in CodeConcept.LOINC
                  and Cdg.code in MarkerCodes
            )
              and exists (
                Comp.interpretation I
                  where Matches(I.text, TextPattern)
              )
        )
  )

define function "HasMarkerNegative"(MarkerCodes List<String>):
  "HasTestObservationWithInterpretationAndValuePattern"(MarkerCodes, { 'NEG' }, '(?i).*([-−]|0|陰性|negative).*')
  or "HasGeneInfoObservationWithInterpretationAndTextPattern"(MarkerCodes, { 'NEG' }, '(?i).*([-−]|0|陰性|negative).*')

define function "HasMarkerNegativeTest"(MarkerCodes List<String>):
  "HasTestObservationWithInterpretationAndValuePattern"(MarkerCodes, { 'NEG' }, '(?i).*([-−]|0|陰性|negative).*')

define function "HasMarkerNegativeGene"(MarkerCodes List<String>):
  "HasGeneInfoObservationWithInterpretationAndTextPattern"(MarkerCodes, { 'NEG' }, '(?i).*([-−]|0|陰性|negative).*')

define function "HasMarkerNegativeWithGeneLoinc"(MarkerCodes List<String>):
  "HasTestObservationWithInterpretationAndValuePattern"(MarkerCodes, { 'NEG' }, '(?i).*([-−]|0|陰性|negative).*')
  or "HasGeneInfoObservationWithInterpretationAndTextPattern"(MarkerCodes, { 'NEG' }, '(?i).*([-−]|0|陰性|negative).*')

define function "HasMarkerNegativeWithGeneLoincTest"(MarkerCodes List<String>):
  "HasTestObservationWithInterpretationAndValuePattern"(MarkerCodes, { 'NEG' }, '(?i).*([-−]|0|陰性|negative).*')

define function "HasMarkerNegativeWithGeneLoincGene"(MarkerCodes List<String>):
  "HasGeneInfoObservationWithInterpretationAndTextPattern"(MarkerCodes, { 'NEG' }, '(?i).*([-−]|0|陰性|negative).*')

define function "HasMarkerPositive"(MarkerCodes List<String>):
  "HasTestObservationWithInterpretationAndValuePattern"(MarkerCodes, { 'POS' }, '(?i).*(\+|陽性|positive).*')
  or "HasGeneInfoObservationWithInterpretationAndTextPattern"(MarkerCodes, { 'POS' }, '(?i).*(\+|陽性|positive).*')

define function "HasMarkerPositiveTest"(MarkerCodes List<String>):
  "HasTestObservationWithInterpretationAndValuePattern"(MarkerCodes, { 'POS' }, '(?i).*(\+|陽性|positive).*')

define function "HasMarkerPositiveGene"(MarkerCodes List<String>):
  "HasGeneInfoObservationWithInterpretationAndTextPattern"(MarkerCodes, { 'POS' }, '(?i).*(\+|陽性|positive).*')

define "HasHER2NegativeTest":
  "HasMarkerNegativeWithGeneLoincTest"(CodeConcept.HER2)

define "HasHER2NegativeGene":
  "HasMarkerNegativeWithGeneLoincGene"(CodeConcept.HER2)

define "HasHER2Negative":
  "HasMarkerNegativeWithGeneLoinc"(CodeConcept.HER2)

define "HasHER2OverexpressionTest":
  "HasTestObservationWithValuePattern"(CodeConcept.HER2, '(?i).*(IHC3\+|FISH\+).*')

define "HasHER2OverexpressionGene":
  "HasGeneInfoObservationWithTextPattern"(CodeConcept.HER2, '(?i).*(IHC3\+|FISH\+).*')

define "HasHER2NegativeOrND":
  "HasTestObservationWithInterpretationCodes"(CodeConcept.HER2, { 'NEG', 'ND' })
  or "HasGeneInfoObservationWithInterpretationCodes"(CodeConcept.HER2, { 'NEG', 'ND' })

define "HasHER2NegativeOrNDTest":
  "HasTestObservationWithInterpretationCodes"(CodeConcept.HER2, { 'NEG', 'ND' })

define "HasHER2NegativeOrNDGene":
  "HasGeneInfoObservationWithInterpretationCodes"(CodeConcept.HER2, { 'NEG', 'ND' })

define "HasHER2Overexpression":
  "HasHER2OverexpressionTest"
  or "HasHER2OverexpressionGene"

define "HasHER2LowExpressionTest":
  "HasTestObservationWithValuePattern"(CodeConcept.HER2, '(?i).*(IHC\s*1\+|IHC\s*2\+|ISH-).*')

define "HasHER2LowExpressionGene":
  "HasGeneInfoObservationWithTextPattern"(CodeConcept.HER2, '(?i).*(IHC\s*1\+|IHC\s*2\+|ISH-).*')

define "HasHER2LowExpression":
  "HasHER2LowExpressionTest"
  or "HasHER2LowExpressionGene"

//癌症分期分數或結果為 M1-M9
define "癌症分期分數或結果為M≠0":
  exists (
    [Observation] O
      where exists (
        O.code.coding Cdg
          where Cdg.code = '399390009'
            and Cdg in CodeConcept.SNOMED
      )
        and O.value is not null
        and O.value is FHIR.string
        and Matches((O.value as FHIR.string).value, '.*M[1-9].*')
  )

//癌症分期分數或結果為 M0
define "癌症分期分數或結果為M=0":
  exists (
    [Observation] O
      where exists (
        O.code.coding Cdg
          where Cdg.code = '399390009'
            and Cdg in CodeConcept.SNOMED
      )
        and O.value is not null
        and O.value is FHIR.string
        and Matches((O.value as FHIR.string).value, '.*M0.*')
  )

// 檢查 MedicationRequest 是否有有效的時間資訊
define function "HasValidTiming"(MR MedicationRequest):
  MR.dosageInstruction is not null
  and Count(MR.dosageInstruction) > 0
  and MR.dosageInstruction[0].timing is not null
  and MR.dosageInstruction[0].timing.repeat is not null
  and MR.dosageInstruction[0].timing.repeat.bounds is Period
  and (MR.dosageInstruction[0].timing.repeat.bounds as Period).start is not null
  and (MR.dosageInstruction[0].timing.repeat.bounds as Period).end is not null

// 取得 MedicationRequest 的起始時間
define function "GetStartTime"(MR MedicationRequest):
  FHIRHelpers.ToDateTime((MR.dosageInstruction[0].timing.repeat.bounds as Period).start)

// 取得 MedicationRequest 的結束時間  
define function "GetEndTime"(MR MedicationRequest):
  FHIRHelpers.ToDateTime((MR.dosageInstruction[0].timing.repeat.bounds as Period).end)

// 檢查 Plan 的時間範圍是否在 Order 的時間範圍內
define function "PlanTimeWithinOrderTime"(MRPlan MedicationRequest, MROrder MedicationRequest):
  "HasValidTiming"(MRPlan) 
  and "HasValidTiming"(MROrder)
  and "GetStartTime"(MRPlan) >= "GetStartTime"(MROrder)
  and "GetStartTime"(MRPlan) <= "GetEndTime"(MROrder)
  and "GetEndTime"(MRPlan) >= "GetStartTime"(MROrder)
  and "GetEndTime"(MRPlan) <= "GetEndTime"(MROrder)

// 檢查兩個藥物的時間範圍是否重疊
define function "MedicationTimesOverlap"(MR1 MedicationRequest, MR2 MedicationRequest):
  "HasValidTiming"(MR1) and "HasValidTiming"(MR2)
  and "GetStartTime"(MR1) <= "GetEndTime"(MR2)
  and "GetEndTime"(MR1) >= "GetStartTime"(MR2)

// 檢查 MedicationRequest 是否為指定藥物申請
define function "HasMedicationCode"(MR MedicationRequest, DrugCodes List<String>):
  exists (
    MR.medication.coding Cdg
    where Cdg in CodeConcept.NHIMedication
      and Cdg.code in DrugCodes
  )

// 是否出現指定藥物用藥紀錄，不檢查療程時間
define function "HasMedicationUse"(DrugCodes List<String>):
  exists (
    [MedicationRequest] MR
    where "HasMedicationCode"(MR, DrugCodes)
  )

// 本次藥物申請（plan）
define function "IsMedicationPlan"(MR MedicationRequest, DrugCodes List<String>):
  MR.intent = 'plan'
  and "HasMedicationCode"(MR, DrugCodes)
  and "HasValidTiming"(MR)

// 歷史藥物醫令（order）
define function "IsMedicationOrder"(MR MedicationRequest, DrugCodes List<String>):
  MR.intent = 'order'
  and "HasMedicationCode"(MR, DrugCodes)
  and "HasValidTiming"(MR)

// 指定藥物最近一次本次申請（plan）
define function "LatestMedicationPlan"(DrugCodes List<String>):
  Last(
    [MedicationRequest] MR
      where "IsMedicationPlan"(MR, DrugCodes)
      sort by FHIRHelpers.ToDateTime((dosageInstruction[0].timing.repeat.bounds as Period).start)
  )

// 指定藥物於參考日期前最近一次本次申請（plan）
define function "LatestMedicationPlanBefore"(DrugCodes List<String>, ReferenceDate DateTime):
  Last(
    [MedicationRequest] MR
      where "IsMedicationPlan"(MR, DrugCodes)
        and "GetStartTime"(MR) < ReferenceDate
      sort by FHIRHelpers.ToDateTime((dosageInstruction[0].timing.repeat.bounds as Period).start)
  )

// 指定藥物於參考日期前最近一次已完成醫令（order）
define function "LatestCompletedMedicationOrderBefore"(DrugCodes List<String>, ReferenceDate DateTime):
  Last(
    [MedicationRequest] MR
      where "IsMedicationOrder"(MR, DrugCodes)
        and MR.status = 'completed'
        and "GetStartTime"(MR) < ReferenceDate
      sort by FHIRHelpers.ToDateTime((dosageInstruction[0].timing.repeat.bounds as Period).start)
  )

define function "HasImageReportBetween"(StartDate DateTime, EndDate DateTime):
  exists (
    [DiagnosticReport] Report
    where "IsImageReport"(Report)
      and Report.effective is not null
      and FHIRHelpers.ToDateTime(Report.effective) >= StartDate
      and FHIRHelpers.ToDateTime(Report.effective) < EndDate
  )

define function "HasImageReportBetweenPreviousTreatmentAndCurrentApply"(DrugCodes List<String>):
  exists (
    [MedicationRequest] CurrentMR
    where "IsMedicationPlan"(CurrentMR, DrugCodes)
      and "LatestCompletedMedicationOrderBefore"(DrugCodes, "GetStartTime"(CurrentMR)) is not null
      and "HasImageReportBetween"(
        "GetStartTime"("LatestCompletedMedicationOrderBefore"(DrugCodes, "GetStartTime"(CurrentMR))),
        "GetStartTime"(CurrentMR)
      )
  )

// 歷史藥物療程結束時間早於或等於本次申請療程開始時間
define function "IsBeforeMedicationPlan"(PriorMR MedicationRequest, CurrentMR MedicationRequest):
  "GetEndTime"(PriorMR) <= "GetStartTime"(CurrentMR)

// 兩筆藥物療程期間有重疊
define function "MedicationPeriodsOverlap"(LeftMR MedicationRequest, RightMR MedicationRequest):
  "GetStartTime"(LeftMR) <= "GetEndTime"(RightMR)
  and "GetEndTime"(LeftMR) >= "GetStartTime"(RightMR)

// 任兩種指定藥物用藥紀錄期間是否重疊
define function "HasMedicationPeriodsOverlap"(DrugCodesA List<String>, DrugCodesB List<String>):
  exists (
    [MedicationRequest] MRA
    where "HasMedicationCode"(MRA, DrugCodesA)
      and "HasValidTiming"(MRA)
      and exists (
        [MedicationRequest] MRB
        where MRB.id != MRA.id
          and "HasMedicationCode"(MRB, DrugCodesB)
          and "HasValidTiming"(MRB)
          and "MedicationPeriodsOverlap"(MRA, MRB)
      )
  )

// 是否於本次指定藥物申請前，曾使用過指定歷史藥物
define function "HasPriorMedicationUse"(CurrentDrugCodes List<String>, PriorDrugCodes List<String>):
  exists (
    [MedicationRequest] CurrentMR
    where "IsMedicationPlan"(CurrentMR, CurrentDrugCodes)
      and exists (
        [MedicationRequest] PriorMR
        where "IsMedicationOrder"(PriorMR, PriorDrugCodes)
          and "IsBeforeMedicationPlan"(PriorMR, CurrentMR)
      )
  )

// 是否於本次指定藥物申請前，曾併用兩種指定歷史藥物
define function "HasPriorConcurrentMedicationUse"(CurrentDrugCodes List<String>, PriorDrugCodesA List<String>, PriorDrugCodesB List<String>):
  exists (
    [MedicationRequest] CurrentMR
    where "IsMedicationPlan"(CurrentMR, CurrentDrugCodes)
      and exists (
        [MedicationRequest] PriorA
        where "IsMedicationOrder"(PriorA, PriorDrugCodesA)
          and "IsBeforeMedicationPlan"(PriorA, CurrentMR)
          and exists (
            [MedicationRequest] PriorB
            where "IsMedicationOrder"(PriorB, PriorDrugCodesB)
              and "MedicationPeriodsOverlap"(PriorA, PriorB)
              and "IsBeforeMedicationPlan"(PriorB, CurrentMR)
          )
      )
  )

// 本次指定藥物申請期間，是否與另一指定藥物申請期間重疊
define function "HasConcurrentMedicationPlan"(CurrentDrugCodes List<String>, ConcurrentDrugCodes List<String>):
  exists (
    [MedicationRequest] CurrentMR
    where "IsMedicationPlan"(CurrentMR, CurrentDrugCodes)
      and exists (
        [MedicationRequest] ConcurrentMR
        where ConcurrentMR.id != CurrentMR.id
          and "IsMedicationPlan"(ConcurrentMR, ConcurrentDrugCodes)
          and "MedicationPeriodsOverlap"(CurrentMR, ConcurrentMR)
      )
  )

// 本次指定藥物申請期間，是否與指定藥物用藥紀錄期間重疊
define function "HasConcurrentMedicationUse"(CurrentDrugCodes List<String>, ConcurrentDrugCodes List<String>):
  exists (
    [MedicationRequest] CurrentMR
    where "IsMedicationPlan"(CurrentMR, CurrentDrugCodes)
      and exists (
        [MedicationRequest] ConcurrentMR
        where ConcurrentMR.id != CurrentMR.id
          and "HasMedicationCode"(ConcurrentMR, ConcurrentDrugCodes)
          and "HasValidTiming"(ConcurrentMR)
          and "MedicationPeriodsOverlap"(CurrentMR, ConcurrentMR)
      )
  )

// 本次指定藥物申請期間，是否與指定藥物醫令期間重疊
define function "HasConcurrentMedicationOrder"(CurrentDrugCodes List<String>, ConcurrentDrugCodes List<String>):
  exists (
    [MedicationRequest] CurrentMR
    where "IsMedicationPlan"(CurrentMR, CurrentDrugCodes)
      and exists (
        [MedicationRequest] ConcurrentMR
        where "IsMedicationOrder"(ConcurrentMR, ConcurrentDrugCodes)
          and "MedicationPeriodsOverlap"(CurrentMR, ConcurrentMR)
      )
  )

// 本次指定藥物申請期間，是否同時與兩種指定藥物醫令期間重疊
define function "HasConcurrentMedicationOrders2"(CurrentDrugCodes List<String>, ConcurrentDrugCodesA List<String>, ConcurrentDrugCodesB List<String>):
  exists (
    [MedicationRequest] CurrentMR
    where "IsMedicationPlan"(CurrentMR, CurrentDrugCodes)
      and exists (
        [MedicationRequest] ConcurrentA
        where "IsMedicationOrder"(ConcurrentA, ConcurrentDrugCodesA)
          and "MedicationPeriodsOverlap"(CurrentMR, ConcurrentA)
      )
      and exists (
        [MedicationRequest] ConcurrentB
        where "IsMedicationOrder"(ConcurrentB, ConcurrentDrugCodesB)
          and "MedicationPeriodsOverlap"(CurrentMR, ConcurrentB)
      )
  )

// 本次指定藥物申請期間，是否同時與三種指定藥物醫令期間重疊
define function "HasConcurrentMedicationOrders3"(CurrentDrugCodes List<String>, ConcurrentDrugCodesA List<String>, ConcurrentDrugCodesB List<String>, ConcurrentDrugCodesC List<String>):
  exists (
    [MedicationRequest] CurrentMR
    where "IsMedicationPlan"(CurrentMR, CurrentDrugCodes)
      and exists (
        [MedicationRequest] ConcurrentA
        where "IsMedicationOrder"(ConcurrentA, ConcurrentDrugCodesA)
          and "MedicationPeriodsOverlap"(CurrentMR, ConcurrentA)
      )
      and exists (
        [MedicationRequest] ConcurrentB
        where "IsMedicationOrder"(ConcurrentB, ConcurrentDrugCodesB)
          and "MedicationPeriodsOverlap"(CurrentMR, ConcurrentB)
      )
      and exists (
        [MedicationRequest] ConcurrentC
        where "IsMedicationOrder"(ConcurrentC, ConcurrentDrugCodesC)
          and "MedicationPeriodsOverlap"(CurrentMR, ConcurrentC)
      )
  )

// 指定藥物本次申請療程天數是否未超過上限
define function "HasMedicationPlanDurationWithin"(CurrentDrugCodes List<String>, MaxDays Integer):
  exists (
    [MedicationRequest] CurrentMR
    where "IsMedicationPlan"(CurrentMR, CurrentDrugCodes)
      and difference in days between "GetStartTime"(CurrentMR)
          and "GetEndTime"(CurrentMR) <= MaxDays
  )

define function "HasMedicationPlanPeriodWithinDays"(DrugCodes List<String>, MaxDays Integer):
  "HasMedicationPlanDurationWithin"(DrugCodes, MaxDays)

define function "HasDailyDoseAtMost"(DrugCodes List<String>, MaxValue Decimal, UnitCode String, TimingCode String):
  exists (
    [MedicationRequest] MR
    where "IsMedicationPlan"(MR, DrugCodes)
      and exists (
        MR.dosageInstruction DI
        where exists (
          DI.timing.code.coding C
          where C.code = TimingCode
        )
        and exists (
          DI.doseAndRate DR
          where (DR.dose as FHIR.SimpleQuantity) is not null
            and (DR.dose as FHIR.SimpleQuantity).value <= MaxValue
            and (DR.dose as FHIR.SimpleQuantity).code = UnitCode
        )
      )
  )

// 指定藥物所有申請療程天數加總是否未超過上限
define function "HasMedicationTotalDurationWithin"(DrugCodes List<String>, MaxDays Integer):
  Coalesce(
    Sum(
      [MedicationRequest] MR
      where MR.intent = 'plan'
        and (MR.status is null or MR.status in { 'active', 'completed', 'on-hold' })
        and "HasMedicationCode"(MR, DrugCodes)
        and "HasValidTiming"(MR)
      return
        difference in days between "GetStartTime"(MR)
          and "GetEndTime"(MR)
    ),
    0
  ) <= MaxDays

// 是否有同藥物先前療程與本次療程間隔超過指定天數
define function "HasPriorMedicationGapLongerThan"(CurrentDrugCodes List<String>, GapDays Integer):
  exists (
    [MedicationRequest] CurrentMR
    where "IsMedicationPlan"(CurrentMR, CurrentDrugCodes)
      and exists (
        [MedicationRequest] PreviousMR
        where PreviousMR.id != CurrentMR.id
          and "IsMedicationPlan"(PreviousMR, CurrentDrugCodes)
          and "GetEndTime"(PreviousMR) < "GetStartTime"(CurrentMR)
          and difference in days between "GetEndTime"(PreviousMR)
              and "GetStartTime"(CurrentMR) > GapDays
      )
  )
