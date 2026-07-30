//肺癌_鱗狀非小細胞肺癌第二線用藥(單用) pembrolizumab、nivolumab、atezolizumab
library LCPemNivAteRule1 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

include LCCodeConcept version '1.0.0' called CodeConcept

include LCReusable version '1.0.0' called Reusable

context Patient

//============================================
// 申請紀錄
//============================================

// 本次申請紀錄（以最新一筆申請作為本次申請）
define "申請藥品L01FF02":
  CodeConcept.L01FF02

define "申請藥品L01FF05":
  CodeConcept.L01FF05

define "申請藥品L01FF01":
  CodeConcept.L01FF01

define "申請藥品":
  "申請藥品L01FF02" union "申請藥品L01FF05" union "申請藥品L01FF01"

define "本次申請紀錄L01FF02":
  Reusable."LatestMedicationPlan"("申請藥品L01FF02")

define "本次申請紀錄L01FF05":
  Reusable."LatestMedicationPlan"("申請藥品L01FF05")

define "本次申請紀錄L01FF01":
  Reusable."LatestMedicationPlan"("申請藥品L01FF01")

define "本次申請紀錄":
  Reusable."LatestMedicationPlan"("申請藥品")

define "本次申請起始日期L01FF02":
  Reusable."GetStartTime"("本次申請紀錄L01FF02")

define "本次申請起始日期L01FF05":
  Reusable."GetStartTime"("本次申請紀錄L01FF05")

define "本次申請起始日期L01FF01":
  Reusable."GetStartTime"("本次申請紀錄L01FF01")

define "本次申請起始日期":
  Reusable."GetStartTime"("本次申請紀錄")

// 首次申請紀錄（開始使用申請藥物）
define "首次申請紀錄L01FF02":
  First(
    [MedicationRequest] MR
      where Reusable."IsMedicationPlan"(MR, "申請藥品L01FF02")
      sort by FHIRHelpers.ToDateTime((dosageInstruction[0].timing.repeat.bounds as Period).start)
  )

define "首次申請紀錄L01FF05":
  First(
    [MedicationRequest] MR
      where Reusable."IsMedicationPlan"(MR, "申請藥品L01FF05")
      sort by FHIRHelpers.ToDateTime((dosageInstruction[0].timing.repeat.bounds as Period).start)
  )

define "首次申請紀錄L01FF01":
  First(
    [MedicationRequest] MR
      where Reusable."IsMedicationPlan"(MR, "申請藥品L01FF01")
      sort by FHIRHelpers.ToDateTime((dosageInstruction[0].timing.repeat.bounds as Period).start)
  )

define "首次申請紀錄":
  First(
    [MedicationRequest] MR
      where Reusable."IsMedicationPlan"(MR, "申請藥品")
      sort by FHIRHelpers.ToDateTime((dosageInstruction[0].timing.repeat.bounds as Period).start)
  )

define "首次申請起始日期L01FF02":
  Reusable."GetStartTime"("首次申請紀錄L01FF02")

define "首次申請起始日期L01FF05":
  Reusable."GetStartTime"("首次申請紀錄L01FF05")

define "首次申請起始日期L01FF01":
  Reusable."GetStartTime"("首次申請紀錄L01FF01")

define "首次申請起始日期":
  Reusable."GetStartTime"("首次申請紀錄")

// 前次申請紀錄（本次申請之前最近一次的申請）
define "前次申請紀錄L01FF02":
  Reusable."LatestMedicationPlanBefore"("申請藥品L01FF02", "本次申請起始日期L01FF02")

define "前次申請紀錄L01FF05":
  Reusable."LatestMedicationPlanBefore"("申請藥品L01FF05", "本次申請起始日期L01FF05")

define "前次申請紀錄L01FF01":
  Reusable."LatestMedicationPlanBefore"("申請藥品L01FF01", "本次申請起始日期L01FF01")

define "前次申請紀錄":
  Reusable."LatestMedicationPlanBefore"("申請藥品", "本次申請起始日期")

define "前次申請起始日期L01FF02":
  Reusable."GetStartTime"("前次申請紀錄L01FF02")

define "前次申請起始日期L01FF05":
  Reusable."GetStartTime"("前次申請紀錄L01FF05")

define "前次申請起始日期L01FF01":
  Reusable."GetStartTime"("前次申請紀錄L01FF01")

define "前次申請起始日期":
  Reusable."GetStartTime"("前次申請紀錄")

//============================================
// 主要規定一：初次使用條件
//============================================

/*規則1*/
//條件1:晚期鱗狀非小細胞肺癌
define "疾病資訊":
  exists (
    [Claim] C
      where exists (
        C.diagnosis D
          where exists (
            D.type.text T
              where Matches(T.value, '(?i).*NSCLC.*(Squamous cell carcinoma|鱗狀).*')
          )
      )
  )

define "有檢查報告":
  exists (
    [DiagnosticReport] Report
    where Reusable."IsMolecularReport"(Report)
  )

define "給付適應症條件P011":
  exists (
    [Claim] C
      where exists (
        C.item I
          where exists (
            I.programCode PC
              where exists (
                PC.coding Cdg
                  where Cdg in CodeConcept.NHIApplyReason
                  and Cdg.code = 'P011'
              )
          )
      )
  )

define "1規則1-1=晚期鱗狀非小細胞肺癌":
Reusable."ICD-10使用C34"
and "疾病資訊"
and "有檢查報告"
and "給付適應症條件P011"
and Reusable."用藥線別≠1"
and Reusable."續用註記為1"

//條件2:先前已使用過platinum類化學治療失敗後，又有疾病惡化
define "1規則1-2=已使用過platinum類化學治療失敗後又有疾病惡化":
exists (
    [MedicationRequest] MR
      where Reusable."HasMedicationCode"(MR, CodeConcept.L01XA)
        and Reusable."HasValidTiming"(MR)
        and Reusable."GetEndTime"(MR) < "本次申請起始日期"
  )

//條件3:且EGFR/ALK腫瘤基因為原生型
define "ALK原生型":
  Reusable."HasTestObservationWithValuePattern"(CodeConcept.ALK, '(?i).*wild type.*')
  or Reusable."HasGeneInfoObservationWithTextPattern"(CodeConcept.ALK, '(?i).*wild type.*')

define "EGFR原生型":
  Reusable."HasTestObservationWithValuePattern"(CodeConcept.EGFR, '(?i).*wild type.*')
  or Reusable."HasGeneInfoObservationWithTextPattern"(CodeConcept.EGFR, '(?i).*wild type.*')

define "1規則1-3=且EGFR/ALK腫瘤基因為原生型":
"ALK原生型"
and "EGFR原生型"

//條件4:成人
define "1規則1-4=成人":
  Reusable."IsPatientAdultAt"(date from "本次申請起始日期")

define "1規則1":
"1規則1-1=晚期鱗狀非小細胞肺癌"
and "1規則1-2=已使用過platinum類化學治療失敗後又有疾病惡化"
and "1規則1-3=且EGFR/ALK腫瘤基因為原生型"
and "1規則1-4=成人"

/*規則2*/
//條件1
define "1規則2-1=病人身體狀況良好(ECOG≦1)":
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
    and (OBs.value as FHIR.integer).value <= 1
  )

//條件2:NYHA(the New York Heart Association) Functional Class I或II
define "1規則2-2=NYHA(the New York Heart Association) Functional Class I或II":
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
        and Cdg.code = '88020-3'
    )
    and OBs.value is FHIR.string
    and ((OBs.value as FHIR.string).value = 'Class I' or (OBs.value as FHIR.string).value = 'Class II')
  )

//條件3
//GOT<60U/L及GPT<60U/L
define "GOT<60U/L及GPT<60U/L":
  exists (
    [Observation] OBs
      where Reusable."IsTestObservation"(OBs)
        and exists (
          OBs.code.coding Cdg
            where Cdg in CodeConcept.LOINC
              and Cdg.code in CodeConcept.GOT
        )
        and OBs.value is FHIR.Quantity
        and (OBs.value as FHIR.Quantity).value < 60
  )
  and exists (
    [Observation] OBs
      where Reusable."IsTestObservation"(OBs)
        and exists (
          OBs.code.coding Cdg
            where Cdg in CodeConcept.LOINC
              and Cdg.code in CodeConcept.GPT
        )
        and OBs.value is FHIR.Quantity
        and (OBs.value as FHIR.Quantity).value < 60
  )

//T-bilirubin<1.5mg/dL
define "T-bilirubin<1.5mg/dL":
  exists (
    [Observation] OBs
      where Reusable."IsTestObservation"(OBs)
    and exists (
      OBs.code.coding Cdg
      where Cdg in CodeConcept.LOINC
        and Cdg.code in CodeConcept.Tbilirubin
    )
     and OBs.value is FHIR.Quantity
    and (OBs.value as FHIR.Quantity).value < 1.5
  )

define "1規則2-3":
"GOT<60U/L及GPT<60U/L"
and "T-bilirubin<1.5mg/dL"

//條件4
//Creatinine<1.5mg/dL
define "Creatinine<1.5mg/dL":
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
        and Cdg.code in CodeConcept.Creatinine
    )
     and OBs.value is FHIR.Quantity
    and (OBs.value as FHIR.Quantity).value < 1.5
  )

//eGFR>60mL/min/1.73m2
define "eGFR>60mL/min/1.73m2":
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
        and Cdg.code in CodeConcept.eGFR
    )
     and OBs.value is FHIR.Quantity
    and (OBs.value as FHIR.Quantity).value > 60
  )

define "1規則2-4":
"Creatinine<1.5mg/dL"
and "eGFR>60mL/min/1.73m2"

define "1規則2":
"1規則2-1=病人身體狀況良好(ECOG≦1)"
and "1規則2-2=NYHA(the New York Heart Association) Functional Class I或II"
and "1規則2-3"
and "1規則2-4"

/*規則3*/
//條件1:申請pembrolizumab
define "申請pembrolizumab":
  "本次申請紀錄L01FF02" is not null

define "申請nivolumab":
  "本次申請紀錄L01FF01" is not null

define "申請atezolizumab":
  "本次申請紀錄L01FF05" is not null

//Dako 22C3:TPS≧50%
define "Dako 22C3 TPS≧50%":
  exists (
    [Observation] OBs
      where Reusable."IsTestObservation"(OBs)
        and exists (
          OBs.code.coding Cdg
            where Cdg in CodeConcept.LOINC
              and Cdg.code in CodeConcept."Dako 22C3 TPS"
        )
        and OBs.value is FHIR.Quantity
        and (OBs.value as FHIR.Quantity).value >= 50
  )

//Ventana SP263:TPS≧50%
define "Ventana SP263 TPS≧50%":
  exists (
    [Observation] OBs
      where Reusable."IsTestObservation"(OBs)
        and exists (
          OBs.code.coding Cdg
            where Cdg in CodeConcept.LOINC
              and Cdg.code in CodeConcept."Ventana SP263 TPS"
        )
        and OBs.value is FHIR.Quantity
        and (OBs.value as FHIR.Quantity).value >= 50
  )

//Dako 28-8:TC≧50%
define "Dako 28-8 TPS≧50%":
  exists (
    [Observation] OBs
      where Reusable."IsTestObservation"(OBs)
        and exists (
          OBs.code.coding Cdg
            where Cdg in CodeConcept.LOINC
              and Cdg.code in CodeConcept."Dako 28-8 TC"
        )
        and OBs.value is FHIR.Quantity
        and (OBs.value as FHIR.Quantity).value >= 50
  )

//Ventana SP142):TC≧50%或IC≧10%
define "Ventana SP142 TC≧50%或IC≧10%":
  exists (
    [Observation] OBs
      where Reusable."IsTestObservation"(OBs)
        and exists (
          OBs.code.coding Cdg
            where Cdg in CodeConcept.LOINC
              and Cdg.code in CodeConcept."Ventana SP142 TC IC"
        )
        and OBs.value is FHIR.Quantity
        and (OBs.value as FHIR.Quantity).value >= 50
  )
  or exists (
    [Observation] OBs
      where Reusable."IsTestObservation"(OBs)
        and exists (
          OBs.code.coding Cdg
            where Cdg in CodeConcept.LOINC
              and Cdg.code in CodeConcept."Ventana SP142 TC IC"
        )
        and OBs.value is FHIR.Quantity
        and (OBs.value as FHIR.Quantity).value >= 10
  )

define "1規則3":
  if "申請pembrolizumab" then
    "Dako 22C3 TPS≧50%" or "Ventana SP263 TPS≧50%"
  else if "申請nivolumab" then
    "Dako 28-8 TPS≧50%" or "Ventana SP263 TPS≧50%"
  else if "申請atezolizumab" then
    "Ventana SP142 TC≧50%或IC≧10%"
  else false

/*規則4*/
//條件1
define "1規則4-1=12週內有影像檢查報告":
Reusable."HasRecentImageReport"("本次申請起始日期", 84)

define "使用免疫檢查點抑制劑之治療計畫":
  exists (
    [Claim] C
      where exists (
        C.supportingInfo Cs
          where exists (
            Cs.category.coding coding
              where coding in CodeConcept.NHIPASSupportingInfoType
                and coding.code = 'carePlanDocument'
          )
          and Cs.value is FHIR.Reference
          and exists (
            [DocumentReference] D
              where (Cs.value as FHIR.Reference).reference = 'DocumentReference/' + D.id
                or (Cs.value as FHIR.Reference).reference = D.id
          )
      )
  )

define "1規則4-2=使用免疫檢查點抑制劑之治療計畫":
  "使用免疫檢查點抑制劑之治療計畫"

define "1規則4":
"1規則4-1=12週內有影像檢查報告"
and "1規則4-2=使用免疫檢查點抑制劑之治療計畫"

define "主要規定一":
"本次申請紀錄" is not null
and "1規則1" and "1規則2" and "1規則3" and "1規則4"

//============================================
// 主要規定二：續用條件－治療持續給付
//============================================

/*規則1*/
//條件1
define "2規則1-1=以i-RECIST標準(HCC患者以mRECIST標準)評定藥物療效反應，依下列原則申請續用：有療效反應(PR及CR)者得繼續用藥":
  exists (
    [Observation] RasObservation
      where exists (
        RasObservation.code.coding ObsCodeCoding
          where ObsCodeCoding.code in CodeConcept."IREC疾病狀態評估"
            and ObsCodeCoding in CodeConcept.NHITreatmentAst
      )
      and Reusable."IsObservationDateTimeWithinDaysBefore"(RasObservation, "本次申請起始日期", 84)
      and RasObservation.value is not null
      and RasObservation.value is FHIR.string
      and Matches((RasObservation.value as FHIR.string).value, '(?i).*(iPR|iCR).*')
  )

//條件2
define "2規則1-2=未出現疾病惡化(PD)或未出現中、重度或危及生命之藥物不良反應者，應停止用藥":
  exists (
    [Observation] RasObservation
    where exists (
      RasObservation.code.coding ObsCodeCoding
      where ObsCodeCoding.code in CodeConcept."IREC疾病狀態評估"
        and ObsCodeCoding in CodeConcept.NHITreatmentAst
    )
  )
  and not exists (
    [Observation] RasObservation
    where exists (
      RasObservation.code.coding ObsCodeCoding
      where ObsCodeCoding.code in CodeConcept."IREC疾病狀態評估"
        and ObsCodeCoding in CodeConcept.NHITreatmentAst
    )
    and RasObservation.value is not null
    and RasObservation.value is FHIR.string
    and Matches((RasObservation.value as FHIR.string).value, '(?i).*(iCPD).*')
  )
  and not exists (
    [Claim] C
    where exists (
      C.diagnosis Diag
      where Diag.type.text is not null
        and exists (
          Diag.type.text T
          where T.value is not null
            and Matches(T.value, '(?i).*中、重度或危及生命之藥物不良反應.*')
        )
    )
  )

//條件3
define "2規則1-3=未出現疾病併發症或輕度藥物不良反應等，或沒有暫停用藥超過原事前審查核定日起24週期限者":
  Reusable."醫令類別為1"
  and not (
    Reusable."HasPriorMedicationGapLongerThan"("申請藥品L01FF02", 168)
    or Reusable."HasPriorMedicationGapLongerThan"("申請藥品L01FF01", 168)
    or Reusable."HasPriorMedicationGapLongerThan"("申請藥品L01FF05", 168)
  )

//條件4
define "規則1-4-0=SD評估記錄":
  [Observation] RasObservation
    where exists (
      RasObservation.code.coding ObsCodeCoding
        where ObsCodeCoding.code in CodeConcept."IREC疾病狀態評估"
          and ObsCodeCoding in CodeConcept.NHITreatmentAst
    )
    and RasObservation.value is not null
    and RasObservation.value is FHIR.string
    and Matches((RasObservation.value as FHIR.string).value, '(?i).*(iSD).*')

define "本次iSD評估記錄":
  "規則1-4-0=SD評估記錄" RasObservation
    where Reusable."IsObservationDateTimeWithinDaysBefore"(RasObservation, "本次申請起始日期", 84)

define "前次iSD評估記錄":
  "規則1-4-0=SD評估記錄" RasObservation
    where Reusable."IsObservationDateTimeWithinDaysBefore"(RasObservation, "前次申請起始日期", 84)

define "規則1-4-1=此次與前次皆為iSD":
  exists "本次iSD評估記錄"
  and exists "前次iSD評估記錄"

define "2規則1":
  (
    "2規則1-1=以i-RECIST標準(HCC患者以mRECIST標準)評定藥物療效反應，依下列原則申請續用：有療效反應(PR及CR)者得繼續用藥"
    or (
      exists "規則1-4-0=SD評估記錄"
      and not "規則1-4-1=此次與前次皆為iSD"
    )
  )
  and "2規則1-2=未出現疾病惡化(PD)或未出現中、重度或危及生命之藥物不良反應者，應停止用藥"
  and "2規則1-3=未出現疾病併發症或輕度藥物不良反應等，或沒有暫停用藥超過原事前審查核定日起24週期限者"

/*規則2*/
define "2規則2":
  "1規則2" and "1規則4-1=12週內有影像檢查報告"

//主要規定二
define "主要規定二":
Reusable."續用註記為2" and "2規則1" and "2規則2"

//============================================
// 主要規定三：藥品使用規則
//============================================

/*規則1*/
//條件1:每位病人每個適應症限給付一種免疫檢查點抑制劑且不得互換
define "3規則1=每位病人每個適應症限給付一種免疫檢查點抑制劑且不得互換":
  (
    "本次申請紀錄L01FF02" is not null
    and not Reusable."HasConcurrentMedicationUse"("申請藥品L01FF02", CodeConcept.L01FFexceptL01FF02) //若申請 pembrolizumab (L01FF02)，不可用其他免疫檢查點抑制劑
  )
  or (
    "本次申請紀錄L01FF01" is not null
    and not Reusable."HasConcurrentMedicationUse"("申請藥品L01FF01", CodeConcept.L01FFexceptL01FF01) //若申請 nivolumab (L01FF01)，不可用其他免疫檢查點抑制劑
  )
  or (
    "本次申請紀錄L01FF05" is not null
    and not Reusable."HasConcurrentMedicationUse"("申請藥品L01FF05", CodeConcept.L01FFexceptL01FF05) //若申請 atezolizumab (L01FF05)，不可用其他免疫檢查點抑制劑
  )

//條件2:治療期間亦不可合併申報該適應症之標靶藥物，無效後或給付時程期滿後則不再給付該適應症相關之標靶藥物
define "3規則2=不可存在指定標靶藥物":
  not Reusable."HasConcurrentMedicationUse"("申請藥品", CodeConcept."主要規定三不得併用標靶藥物")

define "3規則3=使用不得超過2年":
  Reusable."HasMedicationTotalDurationWithin"("申請藥品", 730)

define "3規則4=每次申請以12週為限":
  (
    "本次申請紀錄L01FF02" is null
    or Reusable."HasMedicationPlanPeriodWithinDays"("申請藥品L01FF02", 84)
  )
  and (
    "本次申請紀錄L01FF01" is null
    or Reusable."HasMedicationPlanPeriodWithinDays"("申請藥品L01FF01", 84)
  )
  and (
    "本次申請紀錄L01FF05" is null
    or Reusable."HasMedicationPlanPeriodWithinDays"("申請藥品L01FF05", 84)
  )

define "主要規定三":
  "3規則1=每位病人每個適應症限給付一種免疫檢查點抑制劑且不得互換"
  and "3規則2=不可存在指定標靶藥物"
  and "3規則3=使用不得超過2年"
  and "3規則4=每次申請以12週為限"

//============================================
// 檢核結果用：必要資料存在判斷
//============================================

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

define "NSCLC及鱗狀註記資料存在":
  exists (
    [Claim] C
      where exists (
        C.diagnosis D
          where D.type.text is not null
      )
  )

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

define "給付適應症資料存在":
  exists (
    [Claim] C
      where exists (
        C.item I
          where exists (
            I.programCode PC
              where exists (
                PC.coding Cdg
                  where Cdg in CodeConcept.NHIApplyReason
              )
          )
      )
  )

define "platinum類化學治療藥品資料存在":
  Reusable."HasMedicationUse"(CodeConcept.L01XA)

define "ALK檢測資料存在":
  Reusable."HasTestOrGeneInfoObservation"(CodeConcept.ALK)

define "EGFR檢測資料存在":
  Reusable."HasTestOrGeneInfoObservation"(CodeConcept.EGFR)

define "ECOG資料存在":
  Reusable."HasPatientAssessmentObservationCode"({ '89247-1' })

define "NYHA資料存在":
  Reusable."HasPatientAssessmentObservationCode"({ '88020-3' })

define "GOT資料存在":
  Reusable."HasTestObservationCode"(CodeConcept.GOT)

define "GPT資料存在":
  Reusable."HasTestObservationCode"(CodeConcept.GPT)

define "T-bilirubin資料存在":
  Reusable."HasTestObservationCode"(CodeConcept.Tbilirubin)

define "Creatinine資料存在":
  Reusable."HasTestObservationCode"(CodeConcept.Creatinine)

define "eGFR資料存在":
  Reusable."HasTestObservationCode"(CodeConcept.eGFR)

define "PD-L1檢測資料存在":
  Reusable."HasTestObservationCode"(CodeConcept."Dako 22C3 TPS")
  or Reusable."HasTestObservationCode"(CodeConcept."Ventana SP263 TPS")
  or Reusable."HasTestObservationCode"(CodeConcept."Dako 28-8 TC")
  or Reusable."HasTestObservationCode"(CodeConcept."Ventana SP142 TC IC")

define "iRECIST評估資料存在":
  exists (
    [Observation] RasObservation
      where exists (
        RasObservation.code.coding ObsCodeCoding
          where ObsCodeCoding.code in CodeConcept."IREC疾病狀態評估"
            and ObsCodeCoding in CodeConcept.NHITreatmentAst
      )
  )

define "療程期間資料存在":
  exists (
    [MedicationRequest] MR
      where Reusable."IsMedicationPlan"(MR, "申請藥品")
        and Reusable."HasValidTiming"(MR)
  )

define "必要資料皆存在":
  not (
    (
      Reusable."初次申請" and (
          "本次申請紀錄" is null
          or not "主要疾病ICD資料存在"
          or not "NSCLC及鱗狀註記資料存在"
          or not "用藥線別資料存在"
          or not "有檢查報告"
          or not "給付適應症資料存在"
          or not "platinum類化學治療藥品資料存在"
          or not "ALK檢測資料存在"
          or not "EGFR檢測資料存在"
          or Patient.birthDate is null
          or not "ECOG資料存在"
          or not "NYHA資料存在"
          or not "GOT資料存在"
          or not "GPT資料存在"
          or not "T-bilirubin資料存在"
          or not "Creatinine資料存在"
          or not "eGFR資料存在"
          or not "PD-L1檢測資料存在"
          or not "1規則4-1=12週內有影像檢查報告"
          or not "1規則4-2=使用免疫檢查點抑制劑之治療計畫"
        )
    )
    or (
      Reusable."續用申請" and (
          "本次申請紀錄" is null
          or "前次申請紀錄" is null
          or not "iRECIST評估資料存在"
          or not "ECOG資料存在"
          or not "NYHA資料存在"
          or not "GOT資料存在"
          or not "GPT資料存在"
          or not "T-bilirubin資料存在"
          or not "Creatinine資料存在"
          or not "eGFR資料存在"
          or not "1規則4-1=12週內有影像檢查報告"
        )
    )
    or (not "療程期間資料存在")
  )


//============================================
// 列出「符合」項目判斷式
//============================================

define function "符合項目"():
  (if Reusable."初次申請" and "主要規定一"
    then '<主要規定一：初次使用條件>\n' +
         '● 1規則1：晚期鱗狀非小細胞肺癌且符合先前化學治療失敗及基因原生型條件\n' +
         '● 1規則2：病人身體狀況及肝腎功能條件\n' +
         '● 1規則3：申請藥品對應PD-L1表現條件\n' +
         '● 1規則4：12週內影像檢查報告及免疫檢查點抑制劑治療計畫\n\n'
    else if Reusable."初次申請" and (
      "1規則1-1=晚期鱗狀非小細胞肺癌"
      or "1規則1-2=已使用過platinum類化學治療失敗後又有疾病惡化"
      or "1規則1-3=且EGFR/ALK腫瘤基因為原生型"
      or "1規則1-4=成人"
      or "1規則2"
      or "1規則3"
      or "1規則4"
    )
      then '<主要規定一：初次使用條件>\n' +
           (if "1規則1-1=晚期鱗狀非小細胞肺癌" then '● 1規則1-1：晚期鱗狀非小細胞肺癌\n' else '') +
           (if "1規則1-2=已使用過platinum類化學治療失敗後又有疾病惡化" then '● 1規則1-2：已使用過platinum類化學治療失敗後又有疾病惡化\n' else '') +
           (if "1規則1-3=且EGFR/ALK腫瘤基因為原生型" then '● 1規則1-3：EGFR/ALK腫瘤基因原生型\n' else '') +
           (if "1規則1-4=成人" then '● 1規則1-4：成人\n' else '') +
           (if "1規則2" then '● 1規則2：病人身體狀況及肝腎功能條件\n' else '') +
           (if "1規則3" then '● 1規則3：申請藥品對應PD-L1表現條件\n' else '') +
           (if "1規則4" then '● 1規則4：影像檢查報告及治療計畫\n' else '') +
           '\n'
      else '') +

  (if Reusable."續用申請" and "主要規定二"
    then '<主要規定二：續用條件>\n' +
         '● 2規則1：以i-RECIST標準評定療效反應並符合續用原則\n' +
         '● 2規則2：續用仍符合身體狀況、肝腎功能及12週內影像報告條件\n\n'
    else if Reusable."續用申請" and (
      "2規則1"
      or "2規則2"
    )
      then '<主要規定二：續用條件>\n' +
           (if "2規則1" then '● 2規則1：療效反應及續用原則\n' else '') +
           (if "2規則2" then '● 2規則2：續用身體狀況、肝腎功能及影像報告條件\n' else '') +
           '\n'
      else '') +

  (if "主要規定三"
    then '<主要規定三：藥品使用規則>\n' +
         '● 3規則1：每位病人每個適應症限給付一種免疫檢查點抑制劑且不得互換\n' +
         '● 3規則2：不可存在指定標靶藥物\n' +
         '● 3規則3：使用不得超過2年\n' +
         '● 3規則4：每次申請以12週為限\n\n'
    else if "3規則1=每位病人每個適應症限給付一種免疫檢查點抑制劑且不得互換"
      or "3規則2=不可存在指定標靶藥物"
      or "3規則3=使用不得超過2年"
      or "3規則4=每次申請以12週為限"
      then '<主要規定三：藥品使用規則>\n' +
           (if "3規則1=每位病人每個適應症限給付一種免疫檢查點抑制劑且不得互換" then '● 3規則1：免疫檢查點抑制劑未併用或互換\n' else '') +
           (if "3規則2=不可存在指定標靶藥物" then '● 3規則2：未併用指定標靶藥物\n' else '') +
           (if "3規則3=使用不得超過2年" then '● 3規則3：使用未超過2年\n' else '') +
           (if "3規則4=每次申請以12週為限" then '● 3規則4：每次申請以12週為限\n' else '') +
           '\n'
      else '')


//============================================
// 列出「不符合」項目判斷式 - 條件或代碼不符合
//============================================

define function "不符合項目_條件或代碼不符合"():
  (if Reusable."初次申請" and not "主要規定一" and (
    ("主要疾病ICD資料存在" and not Reusable."ICD-10使用C34")
    or ("NSCLC及鱗狀註記資料存在" and not "疾病資訊")
    or ("用藥線別資料存在" and not Reusable."用藥線別≠1")
    or ("給付適應症資料存在" and not "給付適應症條件P011")
    or ("platinum類化學治療藥品資料存在" and not "1規則1-2=已使用過platinum類化學治療失敗後又有疾病惡化")
    or (("ALK檢測資料存在" and "EGFR檢測資料存在") and not "1規則1-3=且EGFR/ALK腫瘤基因為原生型")
    or (Patient.birthDate is not null and not "1規則1-4=成人")
    or ("ECOG資料存在" and not "1規則2-1=病人身體狀況良好(ECOG≦1)")
    or ("NYHA資料存在" and not "1規則2-2=NYHA(the New York Heart Association) Functional Class I或II")
    or (("GOT資料存在" and "GPT資料存在") and not "GOT<60U/L及GPT<60U/L")
    or ("T-bilirubin資料存在" and not "T-bilirubin<1.5mg/dL")
    or ("Creatinine資料存在" and not "Creatinine<1.5mg/dL")
    or ("eGFR資料存在" and not "eGFR>60mL/min/1.73m2")
    or ("PD-L1檢測資料存在" and not "1規則3")
  )
    then '<主要規定一：初次使用條件>\n' +
         (if "主要疾病ICD資料存在" and not Reusable."ICD-10使用C34" then '▲ 1規則1-1：未符合主要疾病ICD代碼C34條件\n' else '') +
         (if "NSCLC及鱗狀註記資料存在" and not "疾病資訊" then '▲ 1規則1-1：未符合NSCLC及鱗狀診斷條件\n' else '') +
         (if "用藥線別資料存在" and not Reusable."用藥線別≠1" then '▲ 1規則1-1：未符合非第一線用藥條件\n' else '') +
         (if "給付適應症資料存在" and not "給付適應症條件P011" then '▲ 1規則1-1：未符合給付適應症P011條件\n' else '') +
         (if "platinum類化學治療藥品資料存在" and not "1規則1-2=已使用過platinum類化學治療失敗後又有疾病惡化" then '▲ 1規則1-2：未符合已使用platinum類化學治療失敗後又有疾病惡化條件\n' else '') +
         (if ("ALK檢測資料存在" and "EGFR檢測資料存在") and not "1規則1-3=且EGFR/ALK腫瘤基因為原生型" then '▲ 1規則1-3：未符合EGFR/ALK腫瘤基因原生型條件\n' else '') +
         (if Patient.birthDate is not null and not "1規則1-4=成人" then '▲ 1規則1-4：申請日時未滿18歲\n' else '') +
         (if "ECOG資料存在" and not "1規則2-1=病人身體狀況良好(ECOG≦1)" then '▲ 1規則2-1：未符合ECOG≦1條件\n' else '') +
         (if "NYHA資料存在" and not "1規則2-2=NYHA(the New York Heart Association) Functional Class I或II" then '▲ 1規則2-2：未符合NYHA Class I或II條件\n' else '') +
         (if ("GOT資料存在" and "GPT資料存在") and not "GOT<60U/L及GPT<60U/L" then '▲ 1規則2-3：未符合GOT<60U/L及GPT<60U/L條件\n' else '') +
         (if "T-bilirubin資料存在" and not "T-bilirubin<1.5mg/dL" then '▲ 1規則2-3：未符合T-bilirubin<1.5mg/dL條件\n' else '') +
         (if "Creatinine資料存在" and not "Creatinine<1.5mg/dL" then '▲ 1規則2-4：未符合Creatinine<1.5mg/dL條件\n' else '') +
         (if "eGFR資料存在" and not "eGFR>60mL/min/1.73m2" then '▲ 1規則2-4：未符合eGFR>60mL/min/1.73m2條件\n' else '') +
         (if "PD-L1檢測資料存在" and not "1規則3" then '▲ 1規則3：未符合申請藥品對應PD-L1表現條件\n' else '') +
         '\n'
    else '') +

  (if Reusable."續用申請" and not "主要規定二" and (
    ("iRECIST評估資料存在" and not "2規則1")
    or ("ECOG資料存在" and not "1規則2-1=病人身體狀況良好(ECOG≦1)")
    or ("NYHA資料存在" and not "1規則2-2=NYHA(the New York Heart Association) Functional Class I或II")
    or (("GOT資料存在" and "GPT資料存在") and not "GOT<60U/L及GPT<60U/L")
    or ("T-bilirubin資料存在" and not "T-bilirubin<1.5mg/dL")
    or ("Creatinine資料存在" and not "Creatinine<1.5mg/dL")
    or ("eGFR資料存在" and not "eGFR>60mL/min/1.73m2")
  )
    then '<主要規定二：續用條件>\n' +
         (if "iRECIST評估資料存在" and not "2規則1" then '▲ 2規則1：未符合i-RECIST療效反應及續用原則\n' else '') +
         (if "ECOG資料存在" and not "1規則2-1=病人身體狀況良好(ECOG≦1)" then '▲ 2規則2：未符合ECOG≦1條件\n' else '') +
         (if "NYHA資料存在" and not "1規則2-2=NYHA(the New York Heart Association) Functional Class I或II" then '▲ 2規則2：未符合NYHA Class I或II條件\n' else '') +
         (if ("GOT資料存在" and "GPT資料存在") and not "GOT<60U/L及GPT<60U/L" then '▲ 2規則2：未符合GOT<60U/L及GPT<60U/L條件\n' else '') +
         (if "T-bilirubin資料存在" and not "T-bilirubin<1.5mg/dL" then '▲ 2規則2：未符合T-bilirubin<1.5mg/dL條件\n' else '') +
         (if "Creatinine資料存在" and not "Creatinine<1.5mg/dL" then '▲ 2規則2：未符合Creatinine<1.5mg/dL條件\n' else '') +
         (if "eGFR資料存在" and not "eGFR>60mL/min/1.73m2" then '▲ 2規則2：未符合eGFR>60mL/min/1.73m2條件\n' else '') +
         '\n'
    else '') +

  (if not "主要規定三" and (
    not "3規則1=每位病人每個適應症限給付一種免疫檢查點抑制劑且不得互換"
    or not "3規則2=不可存在指定標靶藥物"
    or ("療程期間資料存在" and not "3規則3=使用不得超過2年")
    or ("療程期間資料存在" and not "3規則4=每次申請以12週為限")
  )
    then '<主要規定三：藥品使用規則>\n' +
         (if not "3規則1=每位病人每個適應症限給付一種免疫檢查點抑制劑且不得互換" then '▲ 3規則1：未符合每位病人每個適應症限給付一種免疫檢查點抑制劑且不得互換條件\n' else '') +
         (if not "3規則2=不可存在指定標靶藥物" then '▲ 3規則2：治療期間存在指定不得併用標靶藥物\n' else '') +
         (if "療程期間資料存在" and not "3規則3=使用不得超過2年" then '▲ 3規則3：未符合使用不得超過2年條件\n' else '') +
         (if "療程期間資料存在" and not "3規則4=每次申請以12週為限" then '▲ 3規則4：未符合每次申請以12週為限條件\n' else '') +
         '\n'
    else '')


//============================================
// 列出「不符合」項目判斷式 - 必要資料未填寫
//============================================

define function "不符合項目_必要資料未填寫"():
  (if Reusable."初次申請" and (
    "本次申請紀錄" is null
    or not "主要疾病ICD資料存在"
    or not "NSCLC及鱗狀註記資料存在"
    or not "用藥線別資料存在"
    or not "有檢查報告"
    or not "給付適應症資料存在"
    or not "platinum類化學治療藥品資料存在"
    or not "ALK檢測資料存在"
    or not "EGFR檢測資料存在"
    or Patient.birthDate is null
    or not "ECOG資料存在"
    or not "NYHA資料存在"
    or not "GOT資料存在"
    or not "GPT資料存在"
    or not "T-bilirubin資料存在"
    or not "Creatinine資料存在"
    or not "eGFR資料存在"
    or not "PD-L1檢測資料存在"
    or not "1規則4-1=12週內有影像檢查報告"
    or not "1規則4-2=使用免疫檢查點抑制劑之治療計畫"
  )
    then '<主要規定一：初次使用條件>\n' +
         (if "本次申請紀錄" is null then '▲ 1條件申請醫令：未提供Pembrolizumab、Nivolumab或Atezolizumab申請醫令資料\n' else '') +
         (if not "主要疾病ICD資料存在" then '▲ 1規則1-1：未提供主要疾病ICD診斷資料\n' else '') +
         (if not "NSCLC及鱗狀註記資料存在" then '▲ 1規則1-1：未提供NSCLC及鱗狀診斷註記資料\n' else '') +
         (if not "用藥線別資料存在" then '▲ 1規則1-1：未提供用藥線別資料\n' else '') +
         (if not "有檢查報告" then '▲ 1規則1-1：未提供分子或病理檢查報告資料\n' else '') +
         (if not "給付適應症資料存在" then '▲ 1規則1-1：未提供給付適應症資料\n' else '') +
         (if not "platinum類化學治療藥品資料存在" then '▲ 1規則1-2：未提供platinum類化學治療用藥資料\n' else '') +
         (if not "ALK檢測資料存在" then '▲ 1規則1-3：未提供ALK檢測資料\n' else '') +
         (if not "EGFR檢測資料存在" then '▲ 1規則1-3：未提供EGFR檢測資料\n' else '') +
         (if Patient.birthDate is null then '▲ 1規則1-4：未提供病人出生日期資料\n' else '') +
         (if not "ECOG資料存在" then '▲ 1規則2-1：未提供ECOG資料\n' else '') +
         (if not "NYHA資料存在" then '▲ 1規則2-2：未提供NYHA資料\n' else '') +
         (if not "GOT資料存在" then '▲ 1規則2-3：未提供GOT資料\n' else '') +
         (if not "GPT資料存在" then '▲ 1規則2-3：未提供GPT資料\n' else '') +
         (if not "T-bilirubin資料存在" then '▲ 1規則2-3：未提供T-bilirubin資料\n' else '') +
         (if not "Creatinine資料存在" then '▲ 1規則2-4：未提供Creatinine資料\n' else '') +
         (if not "eGFR資料存在" then '▲ 1規則2-4：未提供eGFR資料\n' else '') +
         (if not "PD-L1檢測資料存在" then '▲ 1規則3：未提供PD-L1檢測資料\n' else '') +
         (if not "1規則4-1=12週內有影像檢查報告" then '▲ 1規則4-1：未提供12週內影像檢查報告\n' else '') +
         (if not "1規則4-2=使用免疫檢查點抑制劑之治療計畫" then '▲ 1規則4-2：未提供免疫檢查點抑制劑治療計畫\n' else '') +
         '\n'
    else '') +

  (if Reusable."續用申請" and (
    "本次申請紀錄" is null
    or "前次申請紀錄" is null
    or not "iRECIST評估資料存在"
    or not "ECOG資料存在"
    or not "NYHA資料存在"
    or not "GOT資料存在"
    or not "GPT資料存在"
    or not "T-bilirubin資料存在"
    or not "Creatinine資料存在"
    or not "eGFR資料存在"
    or not "1規則4-1=12週內有影像檢查報告"
  )
    then '<主要規定二：續用條件>\n' +
         (if "本次申請紀錄" is null then '▲ 2條件申請醫令：未提供本次Pembrolizumab、Nivolumab或Atezolizumab申請醫令資料\n' else '') +
         (if "前次申請紀錄" is null then '▲ 2條件前次申請：未提供前次Pembrolizumab、Nivolumab或Atezolizumab申請資料\n' else '') +
         (if not "iRECIST評估資料存在" then '▲ 2規則1：未提供i-RECIST療效評估資料\n' else '') +
         (if not "ECOG資料存在" then '▲ 2規則2：未提供ECOG資料\n' else '') +
         (if not "NYHA資料存在" then '▲ 2規則2：未提供NYHA資料\n' else '') +
         (if not "GOT資料存在" then '▲ 2規則2：未提供GOT資料\n' else '') +
         (if not "GPT資料存在" then '▲ 2規則2：未提供GPT資料\n' else '') +
         (if not "T-bilirubin資料存在" then '▲ 2規則2：未提供T-bilirubin資料\n' else '') +
         (if not "Creatinine資料存在" then '▲ 2規則2：未提供Creatinine資料\n' else '') +
         (if not "eGFR資料存在" then '▲ 2規則2：未提供eGFR資料\n' else '') +
         (if not "1規則4-1=12週內有影像檢查報告" then '▲ 2規則2：未提供12週內影像檢查報告\n' else '') +
         '\n'
    else '') +

  (if not "療程期間資料存在"
    then '<主要規定三：藥品使用規則>\n' +
         '▲ 3規則3/3規則4：未提供療程起迄日期資料\n\n'
    else '')


//============================================
// 審核結果
//============================================

define "肺癌PembrolizumabNivolumabAtezolizumab申請結果_布林":
  case
    when Reusable."初次申請" then (
      "主要規定一"
      and "主要規定三"
    )
    when Reusable."續用申請" then (
      "主要規定二"
      and "主要規定三"
    )
    else false
  end

define "肺癌PembrolizumabNivolumabAtezolizumab申請結果":
  if Reusable."初次申請" and "主要規定一" and "主要規定三"
  then '✓通過：初次使用－肺癌 Pembrolizumab/Nivolumab/Atezolizumab 用藥申請'
  else if Reusable."續用申請" and "主要規定二" and "主要規定三"
  then '✓通過：續用－肺癌 Pembrolizumab/Nivolumab/Atezolizumab 用藥申請'
  else if Reusable."初次申請"
  then '✖不通過：初次使用－肺癌 Pembrolizumab/Nivolumab/Atezolizumab 用藥申請'
  else if Reusable."續用申請"
  then '✖不通過：續用－肺癌 Pembrolizumab/Nivolumab/Atezolizumab 用藥申請'
  else '✖不通過：無法判定申請類型－肺癌 Pembrolizumab/Nivolumab/Atezolizumab 用藥申請'


//============================================
// 報告總結
//============================================

define "報告總結":
  '\n=== 肺癌之 Pembrolizumab/Nivolumab/Atezolizumab 申請審核報告 ===\n' +
  '\n※ 備註：標示為「參考資訊」之檢核項目，係供審核參酌使用，不作為最終【申請結果】判定之依據。\n' +
  '\n【申請類型】' + Reusable."申請類型" + '\n' +
  '\n【●符合項目】\n' +
  (if "符合項目"() = '' then '無\n' else "符合項目"()) +
  '\n【▲不符合項目 - 必要資料未填寫】\n' +
  (if "不符合項目_必要資料未填寫"() = '' then '無\n' else "不符合項目_必要資料未填寫"()) +
  '\n【▲不符合項目 - 條件或代碼不符合】\n' +
  (if "不符合項目_條件或代碼不符合"() = '' then '無\n' else "不符合項目_條件或代碼不符合"()) +
  '\n【申請結果】\n' +
  "肺癌PembrolizumabNivolumabAtezolizumab申請結果" +
  '\n===============================================\n'
