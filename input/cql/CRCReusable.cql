library CRCReusable version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

include CRCCodeConcept version '1.0.0' called CodeConcept

context Patient

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
