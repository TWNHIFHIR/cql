library CRCReusable version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

include CRCCodeConcept version '1.0.0' called CodeConcept


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