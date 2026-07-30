library CRCReusable version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

include CRCCodeConcept version '1.0.0' called CodeConcept

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


//大腸直腸癌疾病代碼：ICD-10-CM = C18、C19、C20、C21
define "主要疾病之ICD-10使用C18、C19、C20、C21":
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
                and Substring(Cdg.code, 0, 3) in CodeConcept.ICDCRC
            )
      )
  )

//註記判斷
define "註記為1":
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


//註記判斷
define "註記為2":
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
    when "註記為1" then '初次使用'
    when "註記為2" then '續用'
    else '無法判斷申請類型'
  end

define "初次申請":
  "申請類型" = '初次使用'

define "續用申請":
  "申請類型" = '續用'

define "申請類型未知":
  "申請類型" = '無法判斷申請類型'

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

// 是否有主要疾病 ICD 診斷資料（不限定是否為 CRC 代碼）
define "主要疾病ICD診斷資料存在":
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
            )
      )
  )

// 是否有用藥線別資料（不限定線別內容）
define "用藥線別資料存在":
  exists (
    [Claim] C
      where exists (
        C.item I
          where exists (
            I.modifier M
              where exists (
                M.coding Cdg
                  where Cdg in CodeConcept.NHILOT
              )
          )
      )
  )


// 是否有本次藥物申請紀錄
// 用於各 Library 的「申請資料存在」
define function "HasMedicationPlanRecord"(PlanRecordMedicationCodes List<String>):
  exists (
    [MedicationRequest] MR
    where MR.intent = 'plan'
      and "HasMedicationCode"(MR, PlanRecordMedicationCodes)
  )

// 指定藥物本次申請療程起迄日期
// 用於各 Library 的「療程期間資料存在」，需搭配療程上限規則與缺資料報告。
define function "HasMedicationPlanTiming"(PlanTimingMedicationCodes List<String>):
  exists (
    [MedicationRequest] MR
    where "IsMedicationPlan"(MR, PlanTimingMedicationCodes)
  )

// 是否有歷史藥物醫令紀錄
define function "HasMedicationOrderRecord"(OrderRecordMedicationCodes List<String>):
  exists (
    [MedicationRequest] MR
    where MR.intent = 'order'
      and "HasMedicationCode"(MR, OrderRecordMedicationCodes)
  )

// 是否有任一藥物紀錄
define function "HasMedicationRecord"(MedicationRecordCodes List<String>):
  exists (
    [MedicationRequest] MR
    where "HasMedicationCode"(MR, MedicationRecordCodes)
  )

// 是否有指定類別的 Observation
define function "HasObservationCategory"(CategoryCode String):
  exists (
    [Observation] O
    where exists (
      O.category C
        where exists (
          C.coding Cdg
            where Cdg in CodeConcept.NHIPASSupportingInfoType
              and Cdg.code = CategoryCode
        )
    )
  )

// 是否有指定 LOINC 代碼的 Observation
define function "HasObservationCode"(Codes List<String>):
  exists (
    [Observation] O
    where exists (
      O.code.coding Cdg
      where Cdg in CodeConcept.LOINC
        and Cdg.code in Codes
    )
  )

//============================================
// 共用邏輯：資料存在判斷
// 適用於多個 Library 的必要資料檢查；只判斷資料是否存在，不判斷內容是否符合規則。
//============================================

// 是否有癌症分期資料（不限定 M 值結果）。
define "癌症分期資料存在":
  exists (
    [Observation] O
    where exists (
      O.code.coding Cdg
      where Cdg.code = '399390009'
        and Cdg in CodeConcept.SNOMED
    )
    and O.value is not null
  )

// 是否有影像或檢查報告資料（不限定代碼或時間）。
define "影像或檢查報告資料存在":
  exists (
    [DiagnosticReport] Report
    where Report.effective is not null
  )

//============================================
// 共用邏輯：指定期間內的報告檢核
// 適用於各 Library 的「三個月內有影像檢查報告」與「三個月內有檢查報告」
// 由各 Library 傳入自己的代碼清單
//============================================

// 是否有指定影像報告代碼，且檢查日在參考日期前 90 天內。
define function "HasRecentImageReport"(ReportCodes List<String>, ReferenceDate DateTime):
  exists (
    [DiagnosticReport] O
    where exists (
      O.code.coding Cdg
      where (
        Cdg in CodeConcept.ICD10PCS2023Image
        or Cdg in CodeConcept.ICD10PCS2014Image
      )
      and Cdg.code in ReportCodes
    )
    and O.effective is not null
    and FHIRHelpers.ToDateTime(O.effective) >= ReferenceDate - 90 days
    and FHIRHelpers.ToDateTime(O.effective) <= ReferenceDate
  )

// 是否有指定檢查報告代碼，且檢查日在參考日期前 90 天內。
define function "HasRecentDiagnosticReport"(ReportCodes List<String>, ReferenceDate DateTime):
  exists (
    [DiagnosticReport] O
    where exists (
      O.code.coding Cdg
      where Cdg in CodeConcept.LOINC
      and Cdg.code in ReportCodes
    )
    and O.effective is not null
    and FHIRHelpers.ToDateTime(O.effective) >= ReferenceDate - 90 days
    and FHIRHelpers.ToDateTime(O.effective) <= ReferenceDate
  )

//============================================
// 共用邏輯：癌症分期 M 值檢核
// 適用於各 Library 的 M>=1、M≠0、M≠1 規則
// 目前採 strict 格式，只接受 M 後面緊接數字，例如 M1、T3N1M1
//============================================

// 是否有符合指定 regex 的癌症分期 M 值。
define function "HasCancerStageMValue"(MValuePattern String):
  Count(
    [Observation] O
    where exists (
      O.code.coding Cdg
      where Cdg.code = '399390009'
        and Cdg in CodeConcept.SNOMED
    )
    and O.value is not null
    and O.value is FHIR.string
    and Matches((O.value as FHIR.string).value, MValuePattern)
  ) > 0

define "癌症分期分數或結果為M>=1":
  "HasCancerStageMValue"('.*M[1-9].*')

// M≠0 在現行規則中等同要求 M1-M9
define "癌症分期分數或結果為M≠0":
  "HasCancerStageMValue"('.*M[1-9].*')

// M≠1 在 strict 格式下接受 M0 或 M2-M9，排除 M1
define "癌症分期分數或結果為M≠1":
  "HasCancerStageMValue"('.*M[02-9].*')

//============================================
// 共用邏輯：用藥線別檢核
// 適用於多個 Library 的第一線、第二線、二線以上等線別規則
//============================================

// 是否有指定單一用藥線別。
define function "HasLineOfTherapy"(LineCode String):
  exists (
    [Claim] C
      where exists (
        C.item I
          where exists (
            I.modifier M
              where exists (
                M.coding Cdg
                  where Cdg in CodeConcept.NHILOT
                    and Cdg.code = LineCode
              )
          )
      )
  )

// 是否有指定任一用藥線別。
define function "HasLineOfTherapyIn"(LineCodes List<String>):
  exists (
    [Claim] C
      where exists (
        C.item I
          where exists (
            I.modifier M
              where exists (
                M.coding Cdg
                  where Cdg in CodeConcept.NHILOT
                    and Cdg.code in LineCodes
              )
          )
      )
  )

//============================================
// 共用邏輯：基因檢測與特定治療資料存在
// 適用於多個 Library 的必要資料檢查
//============================================

// 是否有 RAS/KRAS 基因檢測資料。
define "RAS基因檢測資料存在":
  "HasObservationCode"(CodeConcept.GeneTest)
  or exists (
    [Observation] RasObservation
    where exists (
      RasObservation.code.coding Cdg
      where Cdg.code = '69548-6'
        and Cdg in CodeConcept.LOINC
    )
  )

// 是否有 FOLFIRI/FOLFOX 相關化療用藥資料
define "FOLFIRI或FOLFOX化學療法資料存在":
  "HasMedicationRecord"(CodeConcept.L01BC02)
  or "HasMedicationRecord"(CodeConcept.L01XA03)
  or "HasMedicationRecord"(CodeConcept.L01CE02)

// 是否有 anti-EGFR 療法資料
define "AntiEGFR療法資料存在":
  "HasMedicationRecord"(CodeConcept.AntiEGFR)

// 是否有治療反應評估資料（不限定評估結果）
define "治療反應評估資料存在":
  exists (
    [Observation] O
      where exists (
        O.code.coding Cdg
          where (Cdg.code in CodeConcept."IREC疾病狀態評估")
            and Cdg in CodeConcept.NHITreatmentAst
      )
      and O.value is not null
  )

define function "HasValidTiming"(MedicationRequestForTiming MedicationRequest):
  MedicationRequestForTiming.dosageInstruction is not null
  and Count(MedicationRequestForTiming.dosageInstruction) > 0
  and MedicationRequestForTiming.dosageInstruction[0].timing is not null
  and MedicationRequestForTiming.dosageInstruction[0].timing.repeat is not null
  and MedicationRequestForTiming.dosageInstruction[0].timing.repeat.bounds is Period
  and (MedicationRequestForTiming.dosageInstruction[0].timing.repeat.bounds as Period).start is not null
  and (MedicationRequestForTiming.dosageInstruction[0].timing.repeat.bounds as Period).end is not null

// 取得 MedicationRequest 的起始時間
define function "GetStartTime"(MedicationRequestForStart MedicationRequest):
  start of (MedicationRequestForStart.dosageInstruction[0].timing.repeat.bounds as Period)

// 取得 MedicationRequest 的結束時間  
define function "GetEndTime"(MedicationRequestForEnd MedicationRequest):
  end of (MedicationRequestForEnd.dosageInstruction[0].timing.repeat.bounds as Period)

// 檢查 MedicationRequest 是否為指定藥物申請
define function "HasMedicationCode"(MedicationRequestToCheck MedicationRequest, MedicationCodesToCheck List<String>):
  exists (
    MedicationRequestToCheck.medication.coding Cdg
    where Cdg in CodeConcept.NHIMedication
      and Cdg.code in MedicationCodesToCheck
  )

// 是否出現指定藥物用藥紀錄，不檢查療程時間
define function "HasMedicationUse"(MedicationUseCodes List<String>):
  exists (
    [MedicationRequest] MR
    where "HasMedicationCode"(MR, MedicationUseCodes)
  )

// 本次藥物申請（plan）
define function "IsMedicationPlan"(PlanMedicationRequest MedicationRequest, PlanMedicationCodes List<String>):
  PlanMedicationRequest.intent = 'plan'
  and "HasMedicationCode"(PlanMedicationRequest, PlanMedicationCodes)
  and "HasValidTiming"(PlanMedicationRequest)

// 歷史藥物醫令（order）
define function "IsMedicationOrder"(OrderMedicationRequest MedicationRequest, OrderMedicationCodes List<String>):
  OrderMedicationRequest.intent = 'order'
  and "HasMedicationCode"(OrderMedicationRequest, OrderMedicationCodes)
  and "HasValidTiming"(OrderMedicationRequest)

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
      and days between "GetStartTime"(CurrentMR)
          and "GetEndTime"(CurrentMR) <= MaxDays
  )

// 指定藥物所有申請療程天數加總是否未超過上限
define function "HasMedicationTotalDurationWithin"(TotalDurationMedicationCodes List<String>, MaxDays Integer):
  Sum(
    (
      [MedicationRequest] MR
      where MR.intent = 'plan'
        and (MR.status is null or MR.status in { 'active', 'completed', 'on-hold' })
        and "HasMedicationCode"(MR, TotalDurationMedicationCodes)
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
