//肝癌_Atezolizumab/Durvalumab給付規定
library HCCAtezoDurvaRule1 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

include HCCCodeConcept version '1.0.0' called CodeConcept

include HCCReusable version '1.0.0' called Reusable

context Patient

//============================================
// 主要規定一：初次使用條件
//============================================

// 本次申請紀錄
define "本次Atezolizumab申請紀錄":
  Reusable."LatestMedicationPlan"(CodeConcept.L01FF05)

define "本次Durvalumab申請紀錄":
  Reusable."LatestMedicationPlan"(CodeConcept.L01FF03)

define "本次Atezolizumab申請起始日期":
  Reusable."GetStartTime"("本次Atezolizumab申請紀錄")

define "本次Durvalumab申請起始日期":
  Reusable."GetStartTime"("本次Durvalumab申請紀錄")

define "ICD代碼檢核":
Reusable."ICD-10使用C22"

define "給付適應症條件P072":
  exists (
    [Claim] C
      where exists (
        C.item I
          where exists (
            I.programCode PC
              where exists (
                PC.coding Cdg
                  where Cdg in CodeConcept.NHIApplyReason
                  and Cdg.code = 'P072'
              )
          )
      )
  )

define "12周內有影像檢查報告":
  (
    "本次Atezolizumab申請紀錄" is not null
    and Reusable."HasRecentImageReport"("本次Atezolizumab申請起始日期", 84)
  )
  or
  (
    "本次Durvalumab申請紀錄" is not null
    and Reusable."HasRecentImageReport"("本次Durvalumab申請起始日期", 84)
  )

define "癌症分期分數或結果為M≠0":
  Reusable."癌症分期分數或結果為M≠0"

define "癌症分期分數或結果為N≠0":
  Reusable."癌症分期分數或結果為N≠0"

/*規則1*/
//條件1
define "1規則1-1":
"ICD代碼檢核"
and "給付適應症條件P072"
and Reusable."用藥線別=1"
and Reusable."續用註記為1"

//條件2
define "Atezolizumab併用Bevacizumab期間內":
  Reusable."HasConcurrentMedicationOrderWithinPlan"(CodeConcept.L01FF05, CodeConcept.L01FG01)

define "1規則1-2-1":
"Atezolizumab併用Bevacizumab期間內"
and Reusable."用藥線別=1"
and Reusable."續用註記為1"
and "本次Atezolizumab申請紀錄" is not null

define "Durvalumab與Tremelimumab併用":
  Reusable."HasConcurrentMedicationOrderWithinPlan"(CodeConcept.L01FF03, CodeConcept.L01FX20)

define "1規則1-2-2":
"Durvalumab與Tremelimumab併用"
and Reusable."用藥線別=1"
and Reusable."續用註記為1"
and "本次Durvalumab申請紀錄" is not null

define "1規則1-2-3":
"ICD代碼檢核"
and (
  (
    "本次Atezolizumab申請紀錄" is not null
    and exists (
      [MedicationRequest] MR
        where Reusable."HasMedicationCode"(MR,
                CodeConcept.L01EXAll union CodeConcept.L01FG union CodeConcept.L01FF
                union CodeConcept.L01FX union CodeConcept.L01XA union CodeConcept.L01BC
                union CodeConcept.L01DB)
          and Reusable."HasValidTiming"(MR)
          and Reusable."GetEndTime"(MR) < "本次Atezolizumab申請起始日期"
    )
  )
  or
  (
    "本次Durvalumab申請紀錄" is not null
    and exists (
      [MedicationRequest] MR
        where Reusable."HasMedicationCode"(MR,
                CodeConcept.L01EXAll union CodeConcept.L01FG union CodeConcept.L01FF
                union CodeConcept.L01FX union CodeConcept.L01XA union CodeConcept.L01BC
                union CodeConcept.L01DB)
          and Reusable."HasValidTiming"(MR)
          and Reusable."GetEndTime"(MR) < "本次Durvalumab申請起始日期"
    )
  )
)

define "1規則1-2-4":
"ICD代碼檢核"
and "12周內有影像檢查報告"
and "癌症分期分數或結果為M≠0"

define "1規則1-2-5-1":
exists (
    [Claim] C
      where exists (
        C.diagnosis D
          where exists (
            D.type.text T
              where Matches(T.value, '(?i).*無法手術切除.*')
          )
      )
  )
and "12周內有影像檢查報告"

define "1規則1-2-5-2":
exists (
    [Claim] C
      where exists (
        C.diagnosis D
          where exists (
            D.type.text T
              where Matches(T.value, '(?i).*不適合局部治療.*')
          )
      )
  )
and "12周內有影像檢查報告"

define "1規則1-2-5-3":
"12周內有影像檢查報告"
and (
  (
    "本次Atezolizumab申請紀錄" is not null
    and Reusable."HasRecentOPReport"("本次Atezolizumab申請起始日期", 360)
  )
  or
  (
    "本次Durvalumab申請紀錄" is not null
    and Reusable."HasRecentOPReport"("本次Durvalumab申請起始日期", 360)
  )
)

define "1規則1-2-5":
"1規則1-2-5-1" and "1規則1-2-5-2" or "1規則1-2-5-3"

define "3個月內有檢查報告":
  (
    "本次Atezolizumab申請紀錄" is not null
    and Reusable."HasRecentMolecularReportV2"("本次Atezolizumab申請起始日期", 90)
  )
  or
  (
    "本次Durvalumab申請紀錄" is not null
    and Reusable."HasRecentMolecularReportV2"("本次Durvalumab申請起始日期", 90)
  )

define "3個月內有評估報告":
  (
    "本次Atezolizumab申請紀錄" is not null
    and Reusable."HasRecentPatReport"("本次Atezolizumab申請起始日期", 90)
  )
  or
  (
    "本次Durvalumab申請紀錄" is not null
    and Reusable."HasRecentPatReport"("本次Durvalumab申請起始日期", 90)
  )

define "評估結果":
  Reusable."HasChildPughA"

define "1規則1-2-6":
"3個月內有檢查報告" and "3個月內有評估報告" and "評估結果"

define "1規則1-2":
( "1規則1-2-1" or "1規則1-2-2" )
and not "1規則1-2-3" 
and ( "1規則1-2-4" or "1規則1-2-5" )
and "1規則1-2-6"

//條件3
define "1規則1-3-1":
"ICD代碼檢核"
and "12周內有影像檢查報告"
and (
  "癌症分期分數或結果為M≠0"
  or Reusable."癌症分期分數或結果為N≠0"
)

define "1規則1-3-2":
"12周內有影像檢查報告"

define "1規則1-3-3":
"12周內有影像檢查報告"
and (
  (
    "本次Atezolizumab申請紀錄" is not null
    and Reusable."HasRecentOPReportV3"("本次Atezolizumab申請起始日期", 360)
  )
  or
  (
    "本次Durvalumab申請紀錄" is not null
    and Reusable."HasRecentOPReportV3"("本次Durvalumab申請起始日期", 360)
  )
)

define "1規則1-3":
"1規則1-3-1" or "1規則1-3-2" or "1規則1-3-3"

//條件4
define "1規則1-4-1":
exists (
    [Claim] C
      where exists (
        C.diagnosis D
          where exists (
            D.type.text T
              where Matches(T.value, '(?i).*曾接受器官移植.*')
          )
      )
  )

define "1規則1-4-2":
(
  (
    "本次Atezolizumab申請紀錄" is not null
    and exists (
      [MedicationRequest] MR
        where Reusable."HasMedicationCode"(MR,
                CodeConcept.L04A union CodeConcept.L01AA01 union CodeConcept.L01AA02
                union CodeConcept.L01BA01)
          and Reusable."HasValidTiming"(MR)
          and Reusable."GetEndTime"(MR) <= "本次Atezolizumab申請起始日期"
          and (duration in days between Reusable."GetEndTime"(MR) and "本次Atezolizumab申請起始日期") <= 90
    )
  )
  or
  (
    "本次Durvalumab申請紀錄" is not null
    and exists (
      [MedicationRequest] MR
        where Reusable."HasMedicationCode"(MR,
                CodeConcept.L04A union CodeConcept.L01AA01 union CodeConcept.L01AA02
                union CodeConcept.L01BA01)
          and Reusable."HasValidTiming"(MR)
          and Reusable."GetEndTime"(MR) <= "本次Durvalumab申請起始日期"
          and (duration in days between Reusable."GetEndTime"(MR) and "本次Durvalumab申請起始日期") <= 90
    )
  )
)

define "簡要病摘":
exists (
    [Claim] C
      where exists (
        C.diagnosis D
          where exists (
            D.type.text T
              where Matches(T.value, '(?i).*上消化道出血.*')
          )
      )
  )

define "6個月內有上消化道出血影像檢查報告":
  (
    "本次Atezolizumab申請紀錄" is not null
    and Reusable."HasRecentUpperGIBleedingImageReport"("本次Atezolizumab申請起始日期", 180)
  )
  or
  (
    "本次Durvalumab申請紀錄" is not null
    and Reusable."HasRecentUpperGIBleedingImageReport"("本次Durvalumab申請起始日期", 180)
  )

define "1規則1-4-3":
"簡要病摘" and "6個月內有上消化道出血影像檢查報告"

define "1規則1-4":
"1規則1-4-1" or "1規則1-4-2" or "1規則1-4-3"

//條件5
define "Atezolizumab併用Sorafenib或Lenvatinib":
  Reusable."HasConcurrentMedicationUse"(CodeConcept.L01FF05, CodeConcept.L01EX02 union CodeConcept.L01EX08)

define "Durvalumab併用Sorafenib或Lenvatinib":
  Reusable."HasConcurrentMedicationUse"(CodeConcept.L01FF03, CodeConcept.L01EX02 union CodeConcept.L01EX08)

define "1規則1-5":
not (
  (
    "本次Atezolizumab申請紀錄" is not null
    and "Atezolizumab併用Sorafenib或Lenvatinib"
  )
  or
  (
    "本次Durvalumab申請紀錄" is not null
    and "Durvalumab併用Sorafenib或Lenvatinib"
  )
)

define "1規則1":
"1規則1-1"
and "1規則1-2"
and "1規則1-3"
and not "1規則1-4"
and "1規則1-5"

/*規則2*/
//條件1
define "1規則2-1":
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
              and Cdg.code in CodeConcept.ECOG
        )
        and Reusable."GetNumericValue"(OBs.value) is not null
        and Reusable."GetNumericValue"(OBs.value) <= 1
  )

define "1規則2-2":
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
              and Cdg.code in CodeConcept.NYHA
        )
        and Matches(OBs.value, '(?i).*(Class I|Class II).*')
  )

define "1規則2-4-1":
  exists (
    [Observation] OBs
      where Reusable."IsTestObservation"(OBs)
        and exists (
          OBs.code.coding Cdg
            where Cdg in CodeConcept.LOINC
              and Cdg.code in CodeConcept.Creatinine
        )
        and Reusable."GetNumericValue"(OBs.value) is not null
        and Reusable."GetNumericValue"(OBs.value) < 1.5
  )

define "1規則2-4-2":
  exists (
    [Observation] OBs
      where Reusable."IsTestObservation"(OBs)
        and exists (
          OBs.code.coding Cdg
            where Cdg in CodeConcept.LOINC
              and Cdg.code in CodeConcept.eGFR
        )
        and Reusable."GetNumericValue"(OBs.value) is not null
        and Reusable."GetNumericValue"(OBs.value) > 60
  )

define "1規則2-4":
"1規則2-4-1" and "1規則2-4-2"

define "1規則2":
"1規則2-1" and "1規則2-2" and "1規則2-4"

/*規則4*/
//條件1
define "1規則4-1-1":
  (
    "本次Atezolizumab申請紀錄" is not null
    and Reusable."HasRecentImageReportV2"("本次Atezolizumab申請起始日期", 84)
  )
  or
  (
    "本次Durvalumab申請紀錄" is not null
    and Reusable."HasRecentImageReportV2"("本次Durvalumab申請起始日期", 84)
  )

define "1規則4-1-2":
 exists (
    [Claim] C
      where exists (
        C.procedure P
          where P.procedure is FHIR.CodeableConcept
            and exists (
              ((P.procedure as FHIR.CodeableConcept).coding) Cdg
                where Cdg.code in CodeConcept.opCode
            )
      )
  )

define "1規則4-1":
"1規則4-1-1" and "1規則4-1-2"

define "1規則4-2":
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
              where (
                (Cs.value as FHIR.Reference).reference = 'DocumentReference/' + D.id
                or (Cs.value as FHIR.Reference).reference = D.id
              )
              and exists (
                D.content Ct
                  where Ct.attachment.url is not null
              )
          )
      )
  )

define "1規則4":
"1規則4-1" and "1規則4-2"

//主要規定一
define "主要規定一":
"1規則1" and "1規則2" and "1規則4"

//============================================
// 主要規定二：續用條件
//============================================

/*規則1*/
//條件1
//需確認MREC代碼
define "2規則1-1":
  (
    "本次Atezolizumab申請紀錄" is not null
    and exists (
      [Observation] RasObservation
        where exists (
          RasObservation.code.coding ObsCodeCoding
            where ObsCodeCoding.code in CodeConcept."MREC疾病狀態評估"
              and ObsCodeCoding in CodeConcept.NHITreatmentAst
        )
        and Reusable."IsObservationDateTimeWithinDaysBefore"(RasObservation, "本次Atezolizumab申請起始日期", 84)
        and RasObservation.value is not null
        and RasObservation.value is FHIR.string
        and Matches((RasObservation.value as FHIR.string).value, '(?i).*(PR|CR).*')
    )
  )
  or
  (
    "本次Durvalumab申請紀錄" is not null
    and exists (
      [Observation] RasObservation
        where exists (
          RasObservation.code.coding ObsCodeCoding
            where ObsCodeCoding.code in CodeConcept."MREC疾病狀態評估"
              and ObsCodeCoding in CodeConcept.NHITreatmentAst
        )
        and Reusable."IsObservationDateTimeWithinDaysBefore"(RasObservation, "本次Durvalumab申請起始日期", 84)
        and RasObservation.value is not null
        and RasObservation.value is FHIR.string
        and Matches((RasObservation.value as FHIR.string).value, '(?i).*(PR|CR).*')
    )
  )

//條件2
define "簡要病摘-疾病惡化":
exists (
    [Claim] C
      where exists (
        C.diagnosis D
          where exists (
            D.type.text T
              where Matches(T.value, '(?i).*中、重度或危及生命之藥物不良反應.*')
          )
      )
  )

define "MREC疾病狀態評估結果為PD":
  (
    "本次Atezolizumab申請紀錄" is not null
    and exists (
      [Observation] RasObservation
        where exists (
          RasObservation.code.coding ObsCodeCoding
            where ObsCodeCoding.code in CodeConcept."MREC疾病狀態評估"
              and ObsCodeCoding in CodeConcept.NHITreatmentAst
        )
        and Reusable."IsObservationDateTimeWithinDaysBefore"(RasObservation, "本次Atezolizumab申請起始日期", 84)
        and RasObservation.value is not null
        and RasObservation.value is FHIR.string
        and Matches((RasObservation.value as FHIR.string).value, '(?i).*(PD).*')
    )
  )
  or
  (
    "本次Durvalumab申請紀錄" is not null
    and exists (
      [Observation] RasObservation
        where exists (
          RasObservation.code.coding ObsCodeCoding
            where ObsCodeCoding.code in CodeConcept."MREC疾病狀態評估"
              and ObsCodeCoding in CodeConcept.NHITreatmentAst
        )
        and Reusable."IsObservationDateTimeWithinDaysBefore"(RasObservation, "本次Durvalumab申請起始日期", 84)
        and RasObservation.value is not null
        and RasObservation.value is FHIR.string
        and Matches((RasObservation.value as FHIR.string).value, '(?i).*(PD).*')
    )
  )

define "2規則1-2":
"簡要病摘-疾病惡化"
and "MREC疾病狀態評估結果為PD"
and Reusable."續用註記為2"

//條件3
define "Atezolizumab用藥間隔超過168天":
  Reusable."HasPriorMedicationGapLongerThan"(CodeConcept.L01FF05, 168)

define "Durvalumab用藥間隔超過168天":
  Reusable."HasPriorMedicationGapLongerThan"(CodeConcept.L01FF03, 168)

define "前次用藥間隔超過168天":
  "Atezolizumab用藥間隔超過168天" or "Durvalumab用藥間隔超過168天"

define "2規則1-3":
Reusable."續用註記為2"
and "前次用藥間隔超過168天"

//條件4
define "第一次SD":
  (
    "本次Atezolizumab申請紀錄" is not null
    and exists (
      [Observation] RasObservation
        where exists (
          RasObservation.code.coding ObsCodeCoding
            where ObsCodeCoding.code in CodeConcept."MREC疾病狀態評估"
              and ObsCodeCoding in CodeConcept.NHITreatmentAst
        )
        and Reusable."IsObservationDateTimeWithinDaysBefore"(RasObservation, "本次Atezolizumab申請起始日期", 84)
        and RasObservation.value is not null
        and RasObservation.value is FHIR.string
        and Matches((RasObservation.value as FHIR.string).value, '(?i).*(SD).*')
    )
  )
  or
  (
    "本次Durvalumab申請紀錄" is not null
    and exists (
      [Observation] RasObservation
        where exists (
          RasObservation.code.coding ObsCodeCoding
            where ObsCodeCoding.code in CodeConcept."MREC疾病狀態評估"
              and ObsCodeCoding in CodeConcept.NHITreatmentAst
        )
        and Reusable."IsObservationDateTimeWithinDaysBefore"(RasObservation, "本次Durvalumab申請起始日期", 84)
        and RasObservation.value is not null
        and RasObservation.value is FHIR.string
        and Matches((RasObservation.value as FHIR.string).value, '(?i).*(SD).*')
    )
  )

define "2規則1-4-1":
"第一次SD" and Reusable."續用註記為2"

define "第二次SD":
  (
    "本次Atezolizumab申請紀錄" is not null
    and exists (
      [Observation] RasObservation
        where exists (
          RasObservation.code.coding ObsCodeCoding
            where ObsCodeCoding.code in CodeConcept."MREC疾病狀態評估"
              and ObsCodeCoding in CodeConcept.NHITreatmentAst
        )
        and Reusable."IsObservationDateTimeWithinDaysBefore"(RasObservation, "本次Atezolizumab申請起始日期", 84)
        and RasObservation.value is not null
        and RasObservation.value is FHIR.string
        and Matches((RasObservation.value as FHIR.string).value, '(?i).*(此次與前次皆為iSD).*')
    )
  )
  or
  (
    "本次Durvalumab申請紀錄" is not null
    and exists (
      [Observation] RasObservation
        where exists (
          RasObservation.code.coding ObsCodeCoding
            where ObsCodeCoding.code in CodeConcept."MREC疾病狀態評估"
              and ObsCodeCoding in CodeConcept.NHITreatmentAst
        )
        and Reusable."IsObservationDateTimeWithinDaysBefore"(RasObservation, "本次Durvalumab申請起始日期", 84)
        and RasObservation.value is not null
        and RasObservation.value is FHIR.string
        and Matches((RasObservation.value as FHIR.string).value, '(?i).*(此次與前次皆為iSD).*')
    )
  )

define "2規則1-4-2":
"第二次SD" and Reusable."續用註記為2"

define "2規則1-4":
"2規則1-4-1"
and not "2規則1-4-2"

define "2規則1":
"2規則1-1"
and not "2規則1-2"
and not "2規則1-3"
and "2規則1-4"

/*規則2*/
//條件1
define "2規則2-1": "1規則2-1"

//條件2
define "2規則2-2": "1規則2-2"

//條件4
define "2規則2-4": "1規則2-4-1" and "1規則2-4-2"

//條件5
define "2規則2-5": 
"ICD代碼檢核" and "1規則4-1-1"

define "2規則2":
"2規則2-1" and "2規則2-2" and "2規則2-4" and "2規則2-5"

define "主要規定二":
"2規則1" and "2規則2"

//============================================
// 主要規定三：藥品使用規則
//============================================

/*規則1*/
//條件1
define "3規則1-1-1":
"ICD代碼檢核"
and "給付適應症條件P072"
and "本次Atezolizumab申請紀錄" is not null

define "藥品代碼L01FFExceptL01FF05":
  exists (
    [MedicationRequest] MR
      where exists (
        MR.medication.coding Cdg
          where Cdg.code in (CodeConcept.L01FF except CodeConcept.L01FF05)
      )
  )

define "3規則1-1-1-1":
"ICD代碼檢核" and "藥品代碼L01FFExceptL01FF05"
 
 define "3規則1-1-2":
 "ICD代碼檢核"
and "給付適應症條件P072"
and "本次Durvalumab申請紀錄" is not null

define "藥品代碼L01FFExceptL01FF03":
  exists (
    [MedicationRequest] MR
      where exists (
        MR.medication.coding Cdg
          where Cdg.code in (CodeConcept.L01FF except CodeConcept.L01FF03)
      )
  )

define "3規則1-1-2-1":
"ICD代碼檢核" and "藥品代碼L01FFExceptL01FF03"

define "3規則1-1":
  ("3規則1-1-1" and not "3規則1-1-1-1")
  or
  ("3規則1-1-2" and not "3規則1-1-2-1")

//條件2
define "3規則1-2-1":
"ICD代碼檢核"
and "本次Atezolizumab申請紀錄" is not null
and not Reusable."HasConcurrentMedicationUse"(CodeConcept.L01FF05, CodeConcept.L01EXAll union CodeConcept.L01FG)

define "3規則1-2-2":
"ICD代碼檢核"
and "本次Durvalumab申請紀錄" is not null
and not Reusable."HasConcurrentMedicationUse"(CodeConcept.L01FF03, CodeConcept.L01EXAll union CodeConcept.L01FG)

define "3規則1-2":
"3規則1-2-1" or "3規則1-2-2"

define "3規則1":
"3規則1-1" and "3規則1-2"

//規則2
define "cancerDrugType":
  CodeConcept.L01FF03 union CodeConcept.L01FF05

//本次（最新一筆）申請紀錄
define "本次申請紀錄":
  Reusable."LatestMedicationPlan"("cancerDrugType")

//useSdate：本次申請之處方起始日
define "useSdate":
  Reusable."GetStartTime"("本次申請紀錄")

//事前審查藥物預定處方終止日期(useEdate)
define "useEdate":
  Reusable."GetEndTime"("本次申請紀錄")

//第一筆申請紀錄（同品項藥物最早一筆 plan）
define "第一筆申請紀錄":
  First(
    [MedicationRequest] MR
      where Reusable."IsMedicationPlan"(MR, "cancerDrugType")
      sort by FHIRHelpers.ToDateTime((dosageInstruction[0].timing.repeat.bounds as Period).start)
  )

//第一筆useSdate
define "第一筆useSdate":
  Reusable."GetStartTime"("第一筆申請紀錄")

//useEdate - 第一筆useSdate <= 730
define "用藥期間未逾730天":
  "useEdate" is not null
  and "第一筆useSdate" is not null
  and (days between "第一筆useSdate" and "useEdate") <= 730

define "3規則2-3":
"本次申請紀錄" is not null
and "用藥期間未逾730天"

define "用藥期間未逾84天":
  "useSdate" is not null
  and "useEdate" is not null
  and (days between "useSdate" and "useEdate") <= 84

//規則4
define "3規則4-5":
"本次申請紀錄" is not null
and "用藥期間未逾84天"

//主要規定三
define "主要規定三":
"3規則1" and "3規則2-3" and "3規則4-5"

//============================================
// 檢核結果用：必要資料存在判斷
//============================================

define "Atezolizumab申請資料存在":
  Reusable."HasMedicationPlanRecord"(CodeConcept.L01FF05)

define "Durvalumab申請資料存在":
  Reusable."HasMedicationPlanRecord"(CodeConcept.L01FF03)

define "AtezoDurva申請資料存在":
  "Atezolizumab申請資料存在" or "Durvalumab申請資料存在"

define "療程期間資料存在":
  Reusable."HasMedicationPlanTiming"(CodeConcept.L01FF05)
  or Reusable."HasMedicationPlanTiming"(CodeConcept.L01FF03)

define "影像報告資料存在":
  Reusable."影像報告資料存在"

define "影像報告V2資料存在":
  exists (
    [DiagnosticReport] Report
      where Reusable."IsImageReportV2"(Report)
  )

define "分子病理報告資料存在":
  Reusable."分子病理報告資料存在"

define "影像或檢查報告資料存在":
  Reusable."影像或檢查報告資料存在"

define "癌症分期資料存在":
  Reusable."癌症分期資料存在"

define "ECOG評估資料存在":
  Reusable."HasPatientAssessmentObservationCode"(CodeConcept.ECOG)

define "NYHA評估資料存在":
  Reusable."HasPatientAssessmentObservationCode"(CodeConcept.NYHA)

define "ChildPugh評估資料存在":
  Reusable."ChildPugh評估資料存在"

define "腎功能檢驗資料存在":
  Reusable."HasTestObservationCode"(CodeConcept.Creatinine union CodeConcept.eGFR)

define "MREC疾病狀態評估資料存在":
  exists (
    [Observation] RasObservation
      where exists (
        RasObservation.code.coding ObsCodeCoding
          where ObsCodeCoding.code in CodeConcept."MREC疾病狀態評估"
            and ObsCodeCoding in CodeConcept.NHITreatmentAst
      )
  )

define "手術相關資料存在":
  Reusable."手術報告資料存在"
  or exists ([Claim] C where exists (C.procedure P where P.procedure is FHIR.CodeableConcept))

define "器官移植病史資料存在":
  Reusable."HasClaimDiagnosisText"('(?i).*曾接受器官移植.*')

define "免疫抑制劑用藥資料存在":
  exists (
    [MedicationRequest] MR
      where Reusable."HasMedicationCode"(MR,
              CodeConcept.L04A union CodeConcept.L01AA01 union CodeConcept.L01AA02
              union CodeConcept.L01BA01)
        and Reusable."HasValidTiming"(MR)
  )

define "上消化道出血病史資料存在":
  Reusable."HasClaimDiagnosisText"('(?i).*上消化道出血.*')

define "無法手術切除或不適合局部治療說明資料存在":
  Reusable."HasClaimDiagnosisText"('(?i).*(無法手術切除|不適合局部治療).*')

define "疾病惡化說明資料存在":
  Reusable."HasClaimDiagnosisText"('(?i).*中、重度或危及生命之藥物不良反應.*')

define "照護計畫文件資料存在":
  exists (
    [Claim] C
      where exists (
        C.supportingInfo Cs
          where exists (
            Cs.category.coding coding
              where coding in CodeConcept.NHIPASSupportingInfoType
                and coding.code = 'carePlanDocument'
          )
      )
  )

//============================================
// 列出「符合」項目判斷式
//============================================

define function "符合項目"():
  (if Reusable."初次申請" and (
      "1規則1-1" or "1規則1-2" or "1規則1-3" or not "1規則1-4" or "1規則1-5"
      or "1規則2-1" or "1規則2-2" or "1規則2-4"
      or "1規則4-1" or "1規則4-2"
    )
    then '<主要規定一：初次使用條件>\n' +
      (if "1規則1-1" then '● 規則1-1：ICD診斷、給付適應症代碼P072、用藥線別及續用註記符合條件\n' else '') +
      (if "1規則1-2" then '● 規則1-2：符合併用治療條件、無排除藥物治療史，且分期/影像及Child-Pugh評估符合條件\n' else '') +
      (if "1規則1-3" then '● 規則1-3：符合影像檢查、癌症分期或手術相關條件\n' else '') +
      (if not "1規則1-4" then '● 規則1-4：無器官移植、近期免疫抑制劑使用或上消化道出血病史等排除情形\n' else '') +
      (if "1規則1-5" then '● 規則1-5：未與Sorafenib或Lenvatinib併用\n' else '') +
      (if "1規則2-1" then '● 規則2-1：ECOG PS<=1\n' else '') +
      (if "1規則2-2" then '● 規則2-2：NYHA Class I或II\n' else '') +
      (if "1規則2-4" then '● 規則2-4：肌酸酐<1.5 mg/dL且eGFR>60\n' else '') +
      (if "1規則4-1" then '● 規則4-1：12週內有影像檢查報告及相符之處置紀錄（參考資訊）\n' else '') +
      (if "1規則4-2" then '● 規則4-2：具治療照護計畫文件（參考資訊）\n' else '') +
      '\n'
    else '') +
  (if Reusable."續用申請" and (
      "2規則1-1" or not "2規則1-2" or not "2規則1-3" or "2規則1-4"
      or "2規則2-1" or "2規則2-2" or "2規則2-4" or "2規則2-5"
    )
    then '<主要規定二：續用條件>\n' +
      (if "2規則1-1" then '● 續用規則1-1：MREC疾病狀態評估結果為PR或CR\n' else '') +
      (if not "2規則1-2" then '● 續用規則1-2：無疾病惡化（無中重度藥物不良反應說明且評估非PD）\n' else '') +
      (if not "2規則1-3" then '● 續用規則1-3：前次用藥間隔未超過168天\n' else '') +
      (if "2規則1-4" then '● 續用規則1-4：SD評估結果符合條件（非連續兩次iSD）\n' else '') +
      (if "2規則2-1" then '● 續用規則2-1：ECOG PS<=1\n' else '') +
      (if "2規則2-2" then '● 續用規則2-2：NYHA Class I或II\n' else '') +
      (if "2規則2-4" then '● 續用規則2-4：肌酸酐<1.5 mg/dL且eGFR>60\n' else '') +
      (if "2規則2-5" then '● 續用規則2-5：ICD診斷及12週內影像檢查報告符合條件\n' else '') +
      '\n'
    else '') +
  (if ("3規則1-1" or "3規則1-2" or "3規則2-3" or "3規則4-5")
    then '<主要規定三：藥品使用規則>\n' +
      (if "3規則1-1" then '● 規則3-1-1：給付適應症代碼P072符合且未使用其他L01FF藥物（參考資訊）\n' else '') +
      (if "3規則1-2" then '● 規則3-1-2：未與其他標靶/免疫藥物併用（參考資訊）\n' else '') +
      (if "3規則2-3" then '● 規則3-2：累計用藥期間未逾730天（參考資訊）\n' else '') +
      (if "3規則4-5" then '● 規則3-4：每次申請事前審查之療程以12週為限（參考資訊）\n' else '') +
      '\n'
    else '')

//============================================
// 列出「不符合」項目判斷式 - 必要資料未填寫
//============================================

define function "不符合項目_必要資料未填寫"():
  (if Reusable."申請類型未知"
    then '▲ 申請類型：未提供可判定初次使用或續用之申請註記\n\n'
    else '') +
  (if Reusable."初次申請" and (
      not "AtezoDurva申請資料存在"
      or not Reusable."主要疾病ICD診斷資料存在"
      or not "影像或檢查報告資料存在"
      or not "ECOG評估資料存在"
      or not "NYHA評估資料存在"
      or not "腎功能檢驗資料存在"
      or not "影像報告V2資料存在"
      or not "照護計畫文件資料存在"
    )
    then '<主要規定一：初次使用條件>\n' +
      (if not "AtezoDurva申請資料存在" then '▲ 申請醫令：未提供Atezolizumab或Durvalumab申請醫令資料\n' else '') +
      (if not Reusable."主要疾病ICD診斷資料存在" then '▲ 規則1-1：未提供主要疾病ICD診斷資料\n' else '') +
      (if not "影像或檢查報告資料存在" then '▲ 規則1-2/1-3：未提供影像檢查或分子病理檢查報告資料\n' else '') +
      (if not "ECOG評估資料存在" then '▲ 規則2-1：未提供ECOG評估資料\n' else '') +
      (if not "NYHA評估資料存在" then '▲ 規則2-2：未提供NYHA評估資料\n' else '') +
      (if not "腎功能檢驗資料存在" then '▲ 規則2-4：未提供肌酸酐或eGFR檢驗資料\n' else '') +
      (if not "影像報告V2資料存在" then '▲ 規則4-1：未提供影像檢查報告資料\n' else '') +
      (if not "照護計畫文件資料存在" then '▲ 規則4-2：未提供治療照護計畫文件資料\n' else '') +
      '\n'
    else '') +
  (if Reusable."續用申請" and (
      not "AtezoDurva申請資料存在"
      or not "MREC疾病狀態評估資料存在"
      or not "ECOG評估資料存在"
      or not "NYHA評估資料存在"
      or not "腎功能檢驗資料存在"
      or not "影像報告V2資料存在"
    )
    then '<主要規定二：續用條件>\n' +
      (if not "AtezoDurva申請資料存在" then '▲ 申請醫令：未提供Atezolizumab或Durvalumab申請醫令資料\n' else '') +
      (if not "MREC疾病狀態評估資料存在" then '▲ 續用規則1：未提供MREC疾病狀態評估資料\n' else '') +
      (if not "ECOG評估資料存在" then '▲ 續用規則2-1：未提供ECOG評估資料\n' else '') +
      (if not "NYHA評估資料存在" then '▲ 續用規則2-2：未提供NYHA評估資料\n' else '') +
      (if not "腎功能檢驗資料存在" then '▲ 續用規則2-4：未提供肌酸酐或eGFR檢驗資料\n' else '') +
      (if not "影像報告V2資料存在" then '▲ 續用規則2-5：未提供影像檢查報告資料\n' else '') +
      '\n'
    else '') +
  (if not "療程期間資料存在"
    then '<主要規定三：藥品使用規則>\n▲ 規則3：未提供療程起迄日期資料（參考資訊）\n\n'
    else '')

//============================================
// 列出「不符合」項目判斷式 - 條件或代碼不符合
//============================================

define function "不符合項目_條件或代碼不符合"():
  (if Reusable."初次申請" and (
      ("AtezoDurva申請資料存在" and not "1規則1-1")
      or ("影像或檢查報告資料存在" and not "1規則1-2")
      or ("影像或檢查報告資料存在" and not "1規則1-3")
      or (("器官移植病史資料存在" or "免疫抑制劑用藥資料存在" or "上消化道出血病史資料存在") and "1規則1-4")
      or not "1規則1-5"
      or ("ECOG評估資料存在" and not "1規則2-1")
      or ("NYHA評估資料存在" and not "1規則2-2")
      or ("腎功能檢驗資料存在" and not "1規則2-4")
      or ("影像報告V2資料存在" and not "1規則4-1")
      or ("照護計畫文件資料存在" and not "1規則4-2")
    )
    then '<主要規定一：初次使用條件>\n' +
      (if "AtezoDurva申請資料存在" and not "1規則1-1" then '▲ 規則1-1：ICD診斷、給付適應症代碼P072、用藥線別或續用註記不符合條件\n' else '') +
      (if "影像或檢查報告資料存在" and not "1規則1-2" then '▲ 規則1-2：併用治療、排除藥物治療史、分期/影像或Child-Pugh評估不符合條件\n' else '') +
      (if "影像或檢查報告資料存在" and not "1規則1-3" then '▲ 規則1-3：影像檢查、癌症分期或手術相關資料不符合條件\n' else '') +
      (if ("器官移植病史資料存在" or "免疫抑制劑用藥資料存在" or "上消化道出血病史資料存在") and "1規則1-4" then '▲ 規則1-4：資料顯示有器官移植、近期免疫抑制劑使用或上消化道出血病史等排除情形\n' else '') +
      (if not "1規則1-5" then '▲ 規則1-5：資料顯示與Sorafenib或Lenvatinib併用，不符合條件\n' else '') +
      (if "ECOG評估資料存在" and not "1規則2-1" then '▲ 規則2-1：ECOG評估結果不符合PS<=1\n' else '') +
      (if "NYHA評估資料存在" and not "1規則2-2" then '▲ 規則2-2：NYHA評估結果不符合Class I或II\n' else '') +
      (if "腎功能檢驗資料存在" and not "1規則2-4" then '▲ 規則2-4：肌酸酐或eGFR檢驗結果不符合條件\n' else '') +
      (if "影像報告V2資料存在" and not "1規則4-1" then '▲ 規則4-1：影像檢查報告或相符處置紀錄不符合條件（參考資訊）\n' else '') +
      (if "照護計畫文件資料存在" and not "1規則4-2" then '▲ 規則4-2：治療照護計畫文件不符合條件（參考資訊）\n' else '') +
      '\n'
    else '') +
  (if Reusable."續用申請" and (
      ("MREC疾病狀態評估資料存在" and not "2規則1-1")
      or "2規則1-2"
      or "2規則1-3"
      or ("MREC疾病狀態評估資料存在" and not "2規則1-4")
      or ("ECOG評估資料存在" and not "2規則2-1")
      or ("NYHA評估資料存在" and not "2規則2-2")
      or ("腎功能檢驗資料存在" and not "2規則2-4")
      or ("影像報告V2資料存在" and not "2規則2-5")
    )
    then '<主要規定二：續用條件>\n' +
      (if "MREC疾病狀態評估資料存在" and not "2規則1-1" then '▲ 續用規則1-1：MREC疾病狀態評估結果非PR或CR\n' else '') +
      (if "2規則1-2" then '▲ 續用規則1-2：資料顯示疾病惡化（中重度藥物不良反應且評估為PD）\n' else '') +
      (if "2規則1-3" then '▲ 續用規則1-3：前次用藥間隔超過168天\n' else '') +
      (if "MREC疾病狀態評估資料存在" and not "2規則1-4" then '▲ 續用規則1-4：連續兩次iSD評估結果不符合條件\n' else '') +
      (if "ECOG評估資料存在" and not "2規則2-1" then '▲ 續用規則2-1：ECOG評估結果不符合PS<=1\n' else '') +
      (if "NYHA評估資料存在" and not "2規則2-2" then '▲ 續用規則2-2：NYHA評估結果不符合Class I或II\n' else '') +
      (if "腎功能檢驗資料存在" and not "2規則2-4" then '▲ 續用規則2-4：肌酸酐或eGFR檢驗結果不符合條件\n' else '') +
      (if "影像報告V2資料存在" and not "2規則2-5" then '▲ 續用規則2-5：ICD診斷或12週內影像檢查報告不符合條件\n' else '') +
      '\n'
    else '') +
  (if "療程期間資料存在" and (not "3規則1-1" or not "3規則1-2" or not "3規則2-3" or not "3規則4-5")
    then '<主要規定三：藥品使用規則>\n' +
      (if not "3規則1-1" then '▲ 規則3-1-1：給付適應症代碼或藥品品項不符合條件（參考資訊）\n' else '') +
      (if not "3規則1-2" then '▲ 規則3-1-2：與其他標靶/免疫藥物併用，不符合條件（參考資訊）\n' else '') +
      (if not "3規則2-3" then '▲ 規則3-2：累計用藥期間超過730天上限（參考資訊）\n' else '') +
      (if not "3規則4-5" then '▲ 規則3-4：每次申請事前審查之療程超過12週上限（參考資訊）\n' else '') +
      '\n'
    else '')

//============================================
// 審核結果
//============================================

define "肝癌AtezoDurva申請結果_布林":
  case
    when Reusable."初次申請" then "主要規定一"
    when Reusable."續用申請" then "主要規定二"
    else false
  end

define "肝癌AtezoDurva申請結果":
  if Reusable."初次申請" and "肝癌AtezoDurva申請結果_布林"
  then '✓通過：初次使用－肝癌 Atezolizumab/Durvalumab 用藥申請'
  else if Reusable."續用申請" and "肝癌AtezoDurva申請結果_布林"
  then '✓通過：續用－肝癌 Atezolizumab/Durvalumab 用藥申請'
  else if Reusable."初次申請"
  then '✖不通過：初次使用－肝癌 Atezolizumab/Durvalumab 用藥申請'
  else if Reusable."續用申請"
  then '✖不通過：續用－肝癌 Atezolizumab/Durvalumab 用藥申請'
  else '✖不通過：無法判定申請類型－肝癌 Atezolizumab/Durvalumab 用藥申請'

//============================================
// 審核報告總結
//============================================

define "報告總結":
  '\n=== 肝癌 Atezolizumab/Durvalumab 申請審核報告 ===\n' +
  '\n※ 備註：標示為「參考資訊」之檢核項目，係供審核參酌使用，不作為最終【申請結果】判定之依據。\n' +
  '\n【申請類型】' + Reusable."申請類型" + '\n' +
  '\n【●符合項目】\n' +
  (if "符合項目"() = '' then '無\n' else "符合項目"()) +
  '\n【▲不符合項目 - 必要資料未填寫】\n' +
  (if "不符合項目_必要資料未填寫"() = '' then '無\n' else "不符合項目_必要資料未填寫"()) +
  '\n【▲不符合項目 - 條件或代碼不符合】\n' +
  (if "不符合項目_條件或代碼不符合"() = '' then '無\n' else "不符合項目_條件或代碼不符合"()) +
  '\n【申請結果】\n' +
  "肝癌AtezoDurva申請結果" +
  '\n===============================================\n'