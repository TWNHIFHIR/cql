library LCReusable version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

include LCCodeConcept version '1.0.0' called CodeConcept

context Patient

// 病人年齡計算
// ReferenceDate 使用申請起始日期轉成 Date 後傳入。
define function "PatientAgeInYearsAt"(ReferenceDate Date):
  if Patient.birthDate is null or ReferenceDate is null then null
  else difference in years between
    FHIRHelpers.ToDate(Patient.birthDate)
    and ReferenceDate

define function "IsPatientAtLeastAgeAt"(ReferenceDate Date, MinimumAge Integer):
  "PatientAgeInYearsAt"(ReferenceDate) is not null
  and "PatientAgeInYearsAt"(ReferenceDate) >= MinimumAge

define function "IsPatientYoungerThanAgeAt"(ReferenceDate Date, MaximumAge Integer):
  "PatientAgeInYearsAt"(ReferenceDate) is not null
  and "PatientAgeInYearsAt"(ReferenceDate) < MaximumAge

define function "IsPatientAdultAt"(ReferenceDate Date):
  "IsPatientAtLeastAgeAt"(ReferenceDate, 18)


//肺癌疾病代碼：ICD-10-CM = C34
define "ICD-10使用C34":
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
                and Substring(Cdg.code, 0, 3) in CodeConcept.ICDLC
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
                         and Cdg.code = '1'
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
                         and Cdg.code = '2'
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

define function "IsMolecularReportV2"(Report DiagnosticReport):
  exists (
    Report.code.coding Cdg
    where Cdg in CodeConcept.LOINC
      and Cdg.code in CodeConcept.MolecularReportV2
  )

define function "IsMolecularReport1"(Report DiagnosticReport):
  exists (
    Report.code.coding Cdg
    where Cdg in CodeConcept.LOINC
      and Cdg.code in CodeConcept.MolecularReport1
  )

define function "IsMolecularReport2"(Report DiagnosticReport):
  exists (
    Report.code.coding Cdg
    where Cdg in CodeConcept.LOINC
      and Cdg.code in CodeConcept.MolecularReport2
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

define function "HasRecentMolecularReport1"(ReferenceDate DateTime, LookbackDays Integer):
  exists (
    [DiagnosticReport] Report
    where "IsMolecularReport1"(Report)
      and "IsReportWithinDaysBefore"(Report, ReferenceDate, LookbackDays)
  )

define function "HasRecentMolecularReport2"(ReferenceDate DateTime, LookbackDays Integer):
  exists (
    [DiagnosticReport] Report
    where "IsMolecularReport2"(Report)
      and "IsReportWithinDaysBefore"(Report, ReferenceDate, LookbackDays)
  )


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

//癌症分期分數或結果為 T>=3
define "癌症分期分數或結果為T>=3":
  exists (
    [Observation] O
      where exists (
        O.code.coding Cdg
          where Cdg.code = '399390009'
            and Cdg in CodeConcept.SNOMED
      )
        and O.value is not null
        and O.value is FHIR.string
        and Matches((O.value as FHIR.string).value, '.*T[3-9].*')
  )

//癌症分期分數或結果為 N>=2
define "癌症分期分數或結果為N>=2":
  exists (
    [Observation] O
      where exists (
        O.code.coding Cdg
          where Cdg.code = '399390009'
            and Cdg in CodeConcept.SNOMED
      )
        and O.value is not null
        and O.value is FHIR.string
        and Matches((O.value as FHIR.string).value, '.*N[2-9].*')
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

define function "IsObservationDateTimeWithinDaysBefore"(OBs Observation, ReferenceDate DateTime, LookbackDays Integer):
  OBs.effective is FHIR.dateTime
  and ReferenceDate is not null
  and FHIRHelpers.ToDateTime(OBs.effective as FHIR.dateTime) <= ReferenceDate
  and (duration in days between FHIRHelpers.ToDateTime(OBs.effective as FHIR.dateTime) and ReferenceDate) <= LookbackDays

define function "HasTestOrGeneInfoObservation"(MarkerCodes List<String>):
  exists (
    [Observation] OBs
      where ("IsTestObservation"(OBs) or "IsGeneInfoObservation"(OBs))
        and exists (
          OBs.code.coding Cdg
            where Cdg in CodeConcept.LOINC
              and Cdg.code in MarkerCodes
        )
  )

define function "HasTestObservationCode"(TestCodes List<String>):
  exists (
    [Observation] OBs
      where "IsTestObservation"(OBs)
        and exists (
          OBs.code.coding Cdg
            where Cdg in CodeConcept.LOINC
              and Cdg.code in TestCodes
        )
  )

define function "HasPatientAssessmentObservationCode"(AssessmentCodes List<String>):
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
              and Cdg.code in AssessmentCodes
        )
  )

define function "HasTestObservationResult"(MarkerCodes List<String>, ResultCodes List<String>, ValuePattern String):
  exists (
    [Observation] OBs
      where "IsTestObservation"(OBs)
        and exists (
          OBs.code.coding Cdg
            where Cdg in CodeConcept.LOINC
              and Cdg.code in MarkerCodes
        )
        and (
          (OBs.value is FHIR.CodeableConcept
            and exists (
              ((OBs.value as FHIR.CodeableConcept).coding) ValueCoding
                where ValueCoding in CodeConcept.InterpretationCodes
                  and ValueCoding.code in ResultCodes
            )
          )
          or (OBs.value is FHIR.string
            and Matches((OBs.value as FHIR.string).value, ValuePattern)
          )
          or exists (
            OBs.interpretation.coding INT
              where INT in CodeConcept.InterpretationCodes
                and INT.code in ResultCodes
          )
        )
  )

define function "HasRecentTestObservationResult"(MarkerCodes List<String>, ResultCodes List<String>, ValuePattern String, ReferenceDate DateTime, LookbackDays Integer):
  exists (
    [Observation] OBs
      where "IsTestObservation"(OBs)
        and "IsObservationDateTimeWithinDaysBefore"(OBs, ReferenceDate, LookbackDays)
        and exists (
          OBs.code.coding Cdg
            where Cdg in CodeConcept.LOINC
              and Cdg.code in MarkerCodes
        )
        and (
          (OBs.value is FHIR.CodeableConcept
            and exists (
              ((OBs.value as FHIR.CodeableConcept).coding) ValueCoding
                where ValueCoding in CodeConcept.InterpretationCodes
                  and ValueCoding.code in ResultCodes
            )
          )
          or (OBs.value is FHIR.string
            and Matches((OBs.value as FHIR.string).value, ValuePattern)
          )
          or exists (
            OBs.interpretation.coding INT
              where INT in CodeConcept.InterpretationCodes
                and INT.code in ResultCodes
          )
        )
  )

define function "HasGeneInfoComponentResult"(MarkerCodes List<String>, ResultCodes List<String>, ValuePattern String):
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
              and (
                (Comp.value is FHIR.CodeableConcept
                  and exists (
                    ((Comp.value as FHIR.CodeableConcept).coding) ValueCoding
                      where ValueCoding in CodeConcept.InterpretationCodes
                        and ValueCoding.code in ResultCodes
                  )
                )
                or (Comp.value is FHIR.string
                  and Matches((Comp.value as FHIR.string).value, ValuePattern)
                )
              )
        )
  )

define function "HasRecentGeneInfoComponentResult"(MarkerCodes List<String>, ResultCodes List<String>, ValuePattern String, ReferenceDate DateTime, LookbackDays Integer):
  exists (
    [Observation] OBs
      where "IsGeneInfoObservation"(OBs)
        and "IsGenePanelObservation"(OBs)
        and "IsObservationDateTimeWithinDaysBefore"(OBs, ReferenceDate, LookbackDays)
        and exists (
          OBs.component Comp
            where exists (
              Comp.code.coding Cdg
                where Cdg in CodeConcept.LOINC
                  and Cdg.code in MarkerCodes
            )
              and (
                (Comp.value is FHIR.CodeableConcept
                  and exists (
                    ((Comp.value as FHIR.CodeableConcept).coding) ValueCoding
                      where ValueCoding in CodeConcept.InterpretationCodes
                        and ValueCoding.code in ResultCodes
                  )
                )
                or (Comp.value is FHIR.string
                  and Matches((Comp.value as FHIR.string).value, ValuePattern)
                )
              )
        )
  )

define function "HasTestObservationWithInterpretationAndValuePattern"(MarkerCodes List<String>, InterpretationCodes List<String>, ValuePattern String):
  "HasTestObservationResult"(MarkerCodes, InterpretationCodes, ValuePattern)

define function "HasGeneInfoObservationWithInterpretationAndTextPattern"(MarkerCodes List<String>, InterpretationCodes List<String>, TextPattern String):
  "HasGeneInfoComponentResult"(MarkerCodes, InterpretationCodes, TextPattern)

define function "HasTestObservationWithInterpretationCodes"(MarkerCodes List<String>, InterpretationCodes List<String>):
  exists (
    [Observation] OBs
      where "IsTestObservation"(OBs)
        and exists (
          OBs.code.coding Cdg
            where Cdg in CodeConcept.LOINC
              and Cdg.code in MarkerCodes
        )
        and (
          (OBs.value is FHIR.CodeableConcept
            and exists (
              ((OBs.value as FHIR.CodeableConcept).coding) ValueCoding
                where ValueCoding in CodeConcept.InterpretationCodes
                  and ValueCoding.code in InterpretationCodes
            )
          )
          or exists (
            OBs.interpretation.coding INT
              where INT in CodeConcept.InterpretationCodes
                and INT.code in InterpretationCodes
          )
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
              and Comp.value is FHIR.CodeableConcept
              and exists (
                ((Comp.value as FHIR.CodeableConcept).coding) INT
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
        and OBs.value is FHIR.string
        and Matches((OBs.value as FHIR.string).value, ValuePattern)
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
              and Comp.value is FHIR.string
              and Matches((Comp.value as FHIR.string).value, TextPattern)
        )
  )

define function "HasMarkerNegative"(MarkerCodes List<String>):
  "HasTestObservationWithInterpretationAndValuePattern"(MarkerCodes, { 'NEG' }, '(?i).*([-−]|0|陰性|negative|wild type|原生型).*')
  or "HasGeneInfoObservationWithInterpretationAndTextPattern"(MarkerCodes, { 'NEG' }, '(?i).*([-−]|0|陰性|negative|wild type|原生型).*')

define function "HasMarkerNegativeTest"(MarkerCodes List<String>):
  "HasTestObservationWithInterpretationAndValuePattern"(MarkerCodes, { 'NEG' }, '(?i).*([-−]|0|陰性|negative|wild type|原生型).*')

define function "HasMarkerNegativeGene"(MarkerCodes List<String>):
  "HasGeneInfoObservationWithInterpretationAndTextPattern"(MarkerCodes, { 'NEG' }, '(?i).*([-−]|0|陰性|negative|wild type|原生型).*')

define function "HasMarkerPositive"(MarkerCodes List<String>):
  "HasTestObservationWithInterpretationAndValuePattern"(MarkerCodes, { 'POS' }, '(?i).*(\\+|陽性|positive).*')
  or "HasGeneInfoObservationWithInterpretationAndTextPattern"(MarkerCodes, { 'POS' }, '(?i).*(\\+|陽性|positive).*')

define function "HasMarkerPositiveTest"(MarkerCodes List<String>):
  "HasTestObservationWithInterpretationAndValuePattern"(MarkerCodes, { 'POS' }, '(?i).*(\\+|陽性|positive).*')

define function "HasMarkerPositiveGene"(MarkerCodes List<String>):
  "HasGeneInfoObservationWithInterpretationAndTextPattern"(MarkerCodes, { 'POS' }, '(?i).*(\\+|陽性|positive).*')

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
  start of (MR.dosageInstruction[0].timing.repeat.bounds as Period)

// 取得 MedicationRequest 的結束時間
define function "GetEndTime"(MR MedicationRequest):
  end of (MR.dosageInstruction[0].timing.repeat.bounds as Period)

// 檢查 Plan 的時間範圍是否在 Order 的時間範圍內
define function "PlanTimeWithinOrderTime"(MRPlan MedicationRequest, MROrder MedicationRequest):
  "HasValidTiming"(MRPlan)
  and "HasValidTiming"(MROrder)
  and "GetStartTime"(MRPlan) >= "GetStartTime"(MROrder)
  and "GetStartTime"(MRPlan) <= "GetEndTime"(MROrder)
  and "GetEndTime"(MRPlan) >= "GetStartTime"(MROrder)
  and "GetEndTime"(MRPlan) <= "GetEndTime"(MROrder)

// 檢查用藥時間是否落在本次申請療程期間內
define function "MedicationTimeWithinPlanTime"(UseMR MedicationRequest, PlanMR MedicationRequest):
  "HasValidTiming"(UseMR)
  and "HasValidTiming"(PlanMR)
  and "GetStartTime"(UseMR) >= "GetStartTime"(PlanMR)
  and "GetStartTime"(UseMR) <= "GetEndTime"(PlanMR)
  and "GetEndTime"(UseMR) >= "GetStartTime"(PlanMR)
  and "GetEndTime"(UseMR) <= "GetEndTime"(PlanMR)

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

// 本次指定藥物申請期間，是否同時有兩種指定藥物醫令且醫令期間皆落在申請期間內
define function "HasConcurrentMedicationOrders2WithinPlan"(CurrentDrugCodes List<String>, ConcurrentDrugCodesA List<String>, ConcurrentDrugCodesB List<String>):
  exists (
    [MedicationRequest] CurrentMR
    where "IsMedicationPlan"(CurrentMR, CurrentDrugCodes)
      and exists (
        [MedicationRequest] ConcurrentA
        where "IsMedicationOrder"(ConcurrentA, ConcurrentDrugCodesA)
          and "MedicationTimeWithinPlanTime"(ConcurrentA, CurrentMR)
      )
      and exists (
        [MedicationRequest] ConcurrentB
        where "IsMedicationOrder"(ConcurrentB, ConcurrentDrugCodesB)
          and "MedicationTimeWithinPlanTime"(ConcurrentB, CurrentMR)
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
      and days between "GetStartTime"(CurrentMR)
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

define function "HasDailyDoseData"(MR MedicationRequest):
  exists (
    MR.dosageInstruction DI
    where exists (
      DI.timing.code.coding C
      where C.code = 'QD'
    )
    and exists (
      DI.doseAndRate DR
      where (DR.dose as FHIR.SimpleQuantity) is not null
        and (DR.dose as FHIR.SimpleQuantity).code = 'mg'
    )
  )

define function "MedicationRequestDailyDoseMg"(MR MedicationRequest):
  Coalesce(
    Sum(
      MR.dosageInstruction DI
        where exists (
          DI.timing.code.coding C
          where C.code = 'QD'
        )
        return Coalesce(
          Sum(
            DI.doseAndRate DR
              where (DR.dose as FHIR.SimpleQuantity) is not null
                and (DR.dose as FHIR.SimpleQuantity).code = 'mg'
              return (DR.dose as FHIR.SimpleQuantity).value
          ),
          0.0
        )
    ),
    0.0
  )

// 單一處方每日劑量加總（可指定單位與頻次代碼，例如 {tbl}/QD）
define function "MedicationRequestDailyDoseByUnit"(MR MedicationRequest, UnitCode String, TimingCode String):
  Coalesce(
    Sum(
      MR.dosageInstruction DI
        where exists (
          DI.timing.code.coding C
          where C.code = TimingCode
        )
        return Coalesce(
          Sum(
            DI.doseAndRate DR
              where (DR.dose as FHIR.SimpleQuantity) is not null
                and (DR.dose as FHIR.SimpleQuantity).code = UnitCode
              return (DR.dose as FHIR.SimpleQuantity).value
          ),
          0.0
        )
    ),
    0.0
  )

define function "ActiveDailyDoseMgAt"(ReferenceDate DateTime, DrugCodes List<String>):
  Coalesce(
    Sum(
      [MedicationRequest] MR
        where "IsMedicationPlan"(MR, DrugCodes)
          and "GetStartTime"(MR) <= ReferenceDate
          and "GetEndTime"(MR) >= ReferenceDate
        return "MedicationRequestDailyDoseMg"(MR)
    ),
    0.0
  )

// 指定藥物於參考日期當下，所有生效中處方以指定單位加總的每日劑量
define function "ActiveDailyDoseByUnitAt"(ReferenceDate DateTime, DrugCodes List<String>, UnitCode String, TimingCode String):
  Coalesce(
    Sum(
      [MedicationRequest] MR
        where "IsMedicationPlan"(MR, DrugCodes)
          and "GetStartTime"(MR) <= ReferenceDate
          and "GetEndTime"(MR) >= ReferenceDate
        return "MedicationRequestDailyDoseByUnit"(MR, UnitCode, TimingCode)
    ),
    0.0
  )

define function "HasConcurrentDailyDoseAtMost"(DrugCodes List<String>, MaxMg Decimal):
  not exists (
    [MedicationRequest] MR
      where "IsMedicationPlan"(MR, DrugCodes)
        and "ActiveDailyDoseMgAt"("GetStartTime"(MR), DrugCodes) > MaxMg
  )

// 指定藥物是否每日劑量（以指定單位計，如 {tbl}）未超過上限
define function "HasConcurrentDailyDoseAtMost"(DrugCodes List<String>, MaxValue Decimal, UnitCode String, TimingCode String):
  not exists (
    [MedicationRequest] MR
      where "IsMedicationPlan"(MR, DrugCodes)
        and "ActiveDailyDoseByUnitAt"("GetStartTime"(MR), DrugCodes, UnitCode, TimingCode) > MaxValue
  )

// 指定藥物所有申請療程天數加總是否未超過上限
define function "HasMedicationTotalDurationWithin"(DrugCodes List<String>, MaxDays Integer):
  Sum(
    (
      [MedicationRequest] MR
      where MR.intent = 'plan'
        and (MR.status is null or MR.status in { 'active', 'completed', 'on-hold' })
        and "HasMedicationCode"(MR, DrugCodes)
        and "HasValidTiming"(MR)
      return
        days between "GetStartTime"(MR)
          and "GetEndTime"(MR)
    )
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
          and days between "GetEndTime"(PreviousMR)
              and "GetStartTime"(CurrentMR) > GapDays
      )
  )


define function "HasClaimDiagnosisText"(Pattern String):
  exists (
    [Claim] C
      where exists (
        C.diagnosis D
          where exists (
            D.type.text T
              where T.value is not null
                and Matches(T.value, Pattern)
          )
      )
  )

define function "HasReportResultString"(Pattern String):
  exists (
    [DiagnosticReport] DR
      where DR.conclusion is not null
        and Matches(DR.conclusion, Pattern)
  )

























