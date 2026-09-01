library PCReusable version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

include PCCodeConcept version '1.0.0' called CodeConcept

context Patient


//攝護腺癌疾病代碼：ICD-10-CM = C61
define "主要疾病之ICD-10使用C61":
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
                and Substring(Cdg.code, 0, 3) in CodeConcept.ICDPC
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
    else '無法判定申請類型'
  end

define "初次申請":
  "申請類型" = '初次使用'

define "續用申請":
  "申請類型" = '續用'

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

//將 effective[x] 這類 Choice 型別（dateTime/Period/Timing/instant）轉為單一 DateTime，避免 ToDateTime 多載歧義
define function "EffectiveDateTime"(Effective Choice<FHIR.dateTime, FHIR.Period, FHIR.Timing, FHIR.instant>):
  case
    when Effective is FHIR.dateTime then FHIRHelpers.ToDateTime(Effective as FHIR.dateTime)
    when Effective is FHIR.instant then FHIRHelpers.ToDateTime(Effective as FHIR.instant)
    when Effective is FHIR.Period then FHIRHelpers.ToDateTime((Effective as FHIR.Period).start)
    else null
  end

//報告日期是否落在參考日期前指定天數內
define function "IsReportWithinDaysBefore"(Report DiagnosticReport, ReferenceDate DateTime, LookbackDays Integer):
  Report.effective is not null
  and ReferenceDate is not null
  and "EffectiveDateTime"(Report.effective) <= ReferenceDate
  and (duration in days between "EffectiveDateTime"(Report.effective) and ReferenceDate) <= LookbackDays

define function "HasRecentImageReportWithCodes"(ReportCodes List<String>, ReferenceDate DateTime, LookbackDays Integer):
  exists (
    [DiagnosticReport] Report
    where exists (
      Report.code.coding Cdg
      where (
        Cdg in CodeConcept.ICD10PCS2023Image
        or Cdg in CodeConcept.ICD10PCS2014Image
        or Cdg in CodeConcept.NHIMedication
      )
      and Cdg.code in ReportCodes
    )
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

// 檢查用藥時間是否落在本次申請療程期間內
define function "MedicationTimeWithinPlanTime"(UseMR MedicationRequest, PlanMR MedicationRequest):
  "HasValidTiming"(UseMR)
  and "HasValidTiming"(PlanMR)
  and "GetStartTime"(UseMR) >= "GetStartTime"(PlanMR)
  and "GetStartTime"(UseMR) <= "GetEndTime"(PlanMR)
  and "GetEndTime"(UseMR) >= "GetStartTime"(PlanMR)
  and "GetEndTime"(UseMR) <= "GetEndTime"(PlanMR)

// 檢查 MedicationRequest 是否為指定藥物申請
define function "HasMedicationCode"(MR MedicationRequest, DrugCodes List<String>):
  exists (
    MR.medication.coding Cdg
    where Cdg in CodeConcept.NHIMedication
      and Cdg.code in DrugCodes
  )

// 是否存在指定藥物申請紀錄，不要求療程時間完整
define function "HasMedicationPlanRecord"(DrugCodes List<String>):
  exists (
    [MedicationRequest] MR
    where MR.intent = 'plan'
      and "HasMedicationCode"(MR, DrugCodes)
  )

// 是否存在指定藥物申請紀錄且療程起迄時間完整
define function "HasMedicationPlanTiming"(DrugCodes List<String>):
  exists (
    [MedicationRequest] MR
    where MR.intent = 'plan'
      and "HasMedicationCode"(MR, DrugCodes)
      and "HasValidTiming"(MR)
  )

// 是否存在指定藥物任一用藥紀錄
define function "HasMedicationRecord"(DrugCodes List<String>):
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

// 歷史藥物療程結束時間早於或等於本次申請療程開始時間
define function "IsBeforeMedicationPlan"(PriorMR MedicationRequest, CurrentMR MedicationRequest):
  "GetEndTime"(PriorMR) <= "GetStartTime"(CurrentMR)

// 兩筆藥物療程期間有重疊
define function "MedicationPeriodsOverlap"(LeftMR MedicationRequest, RightMR MedicationRequest):
  "GetStartTime"(LeftMR) <= "GetEndTime"(RightMR)
  and "GetEndTime"(LeftMR) >= "GetStartTime"(RightMR)

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

// 本次指定藥物申請期間，是否有指定藥物醫令且醫令期間完全落在申請期間內
define function "HasConcurrentMedicationOrderWithinPlan"(CurrentDrugCodes List<String>, ConcurrentDrugCodes List<String>):
  exists (
    [MedicationRequest] CurrentMR
    where "IsMedicationPlan"(CurrentMR, CurrentDrugCodes)
      and exists (
        [MedicationRequest] ConcurrentMR
        where "IsMedicationOrder"(ConcurrentMR, ConcurrentDrugCodes)
          and "MedicationTimeWithinPlanTime"(ConcurrentMR, CurrentMR)
      )
  )

// 本次指定藥物申請期間，是否存在指定併用藥物醫令，且其醫令期間完全涵蓋本次申請期間（useSdate/useEdate 皆落在併用藥期間內）
define function "HasConcurrentMedicationCoveringPlan"(CurrentDrugCodes List<String>, ConcurrentDrugCodes List<String>):
  exists (
    [MedicationRequest] CurrentMR
    where "IsMedicationPlan"(CurrentMR, CurrentDrugCodes)
      and exists (
        [MedicationRequest] ConcurrentMR
        where ConcurrentMR.id != CurrentMR.id
          and "HasMedicationCode"(ConcurrentMR, ConcurrentDrugCodes)
          and "HasValidTiming"(ConcurrentMR)
          and "MedicationTimeWithinPlanTime"(CurrentMR, ConcurrentMR)
      )
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

// 檢核報告用：是否有主要疾病 ICD 診斷資料
define "主要疾病ICD診斷資料存在":
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

// 檢核報告用：是否有癌症分期資料
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

//影像報告
define function "IsImageReport"(Report DiagnosticReport):
  exists (
    Report.code.coding Cdg
    where (
      Cdg in CodeConcept.ICD10PCS2023Image
      or Cdg in CodeConcept.ICD10PCS2014Image
    )
    and Cdg.code in CodeConcept.Radium223MetastasisImageReportCode
  )

//檢查報告
define function "IsMolecularReport"(Report DiagnosticReport):
  exists (
    Report.code.coding Cdg
    where Cdg in CodeConcept.LOINC
      and Cdg.code in CodeConcept.Olaparib
  )

//期限內有影像檢查報告
define function "HasRecentImageReport"(ReferenceDate DateTime, LookbackDays Integer):
  exists (
    [DiagnosticReport] Report
    where "IsImageReport"(Report)
      and "IsReportWithinDaysBefore"(Report, ReferenceDate, LookbackDays)
  )

//期限內有檢查報告
define function "HasRecentMolecularReport"(ReferenceDate DateTime, LookbackDays Integer):
  exists (
    [DiagnosticReport] Report
    where "IsMolecularReport"(Report)
      and "IsReportWithinDaysBefore"(Report, ReferenceDate, LookbackDays)
  )

//檢驗(查)報告日期是否落在參考日期前指定天數內
define function "IsObservationWithinDaysBefore"(Obs Observation, ReferenceDate DateTime, LookbackDays Integer):
  Obs.effective is not null
  and ReferenceDate is not null
  and "EffectiveDateTime"(Obs.effective) <= ReferenceDate
  and (duration in days between "EffectiveDateTime"(Obs.effective) and ReferenceDate) <= LookbackDays

//檢驗(查)報告日期是否晚於（在）參考日期之後
define function "IsObservationAfter"(Obs Observation, ReferenceDate DateTime):
  Obs.effective is not null
  and ReferenceDate is not null
  and "EffectiveDateTime"(Obs.effective) > ReferenceDate

//報告日期是否晚於（在）參考日期之後
define function "IsReportAfter"(Report DiagnosticReport, ReferenceDate DateTime):
  Report.effective is not null
  and ReferenceDate is not null
  and "EffectiveDateTime"(Report.effective) > ReferenceDate

//參考日期後是否有影像檢查報告
define function "HasImageReportAfter"(ReferenceDate DateTime):
  exists (
    [DiagnosticReport] Report
    where "IsImageReport"(Report)
      and "IsReportAfter"(Report, ReferenceDate)
  )

// 單一處方每日劑量加總（以 mg、QD 計）
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

// 指定藥物於參考日期當下，所有生效中處方以 mg 加總的每日劑量
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

// 指定藥物是否每日劑量（以 mg 計）未超過上限
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
