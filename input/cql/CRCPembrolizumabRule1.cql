//大腸直腸_Pembrolizumab給付規定
library CRCPembrolizumabRule1 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

include CRCCodeConcept version '1.0.0' called CodeConcept

include CRCReusable version '1.0.0' called Reusable
 
context Patient


//============================================
// 主要規定一：初次使用條件
//============================================

// 本次申請紀錄（以最新一筆申請作為本次申請）
define "本次申請紀錄":
  Last(
    [MedicationRequest] MR
      where MR.intent = 'plan'
        and exists (
          MR.medication.coding Cdg
            where Cdg in CodeConcept.NHIMedication
              and Cdg.code in CodeConcept.L01FF02
        )
        and MR.dosageInstruction[0].timing.repeat.bounds is Period
      sort by FHIRHelpers.ToDateTime((dosageInstruction[0].timing.repeat.bounds as Period).start)
  )

define "本次申請起始日期":
  FHIRHelpers.ToDateTime(("本次申請紀錄".dosageInstruction[0].timing.repeat.bounds as Period).start)

define "年齡計算用申請日期":
  date from "本次申請起始日期"

define "申請日時病人年齡歲數":
  Reusable."PatientAgeInYearsAt"("年齡計算用申請日期")

define "是否滿18歲":
  Reusable."IsPatientAdultAt"("年齡計算用申請日期")

/*規則1*/
//條件1-1
define "ICD代碼檢核_布林值": Reusable."主要疾病之ICD-10使用C18、C19、C20、C21"

//條件1-2
define "1規則1-1-2=三個月內有影像檢查報告":
  Reusable."HasRecentImageReport"(CodeConcept.ImageReportTumorCode, "本次申請起始日期")

//條件1-3
define "1規則1-1-3=申請項目":
  exists (
    [MedicationRequest] MRPlan
    where MRPlan.intent = 'plan'
    and exists (
      MRPlan.medication.coding Cdg
      where Cdg.system in CodeConcept.NHIMedication
      and Cdg.code in CodeConcept.L01FF02
    )
  )
  and exists (
    [Claim] C
    where exists (
      C.item I
      where exists (
        I.programCode PC
        where exists (
          PC.coding Coding
          where Coding.code in CodeConcept."P141大腸直腸癌給付適應症"
        )
      )
    )
  )
  and  exists (
    [Claim] C
      where exists (
        C.item I
          where exists (
            I.modifier M
              where exists (
                M.coding Cdg
                  where Cdg.system in CodeConcept.NHILOT
                    and Cdg.code = '1'
            )
        )
    )
  )

define "1規則1-1":
  (Reusable."主要疾病之ICD-10使用C18、C19、C20、C21" 
  and "1規則1-1-3=申請項目")
  or "1規則1-1-2=三個月內有影像檢查報告" 

//條件3
define "1規則1-3=做為無法切除":
  exists (
    [Claim] C
    where exists (
      C.diagnosis Diag
      where Diag.type.text is not null
        and exists (
          Diag.type.text T
          where Matches(T, '(?i).*無法切除.*')
        )
    )
  )

//條件4
define "1規則1-4=或轉移性高微衛星不穩定性(MSI-H)":
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
        and Cdg.code in CodeConcept.inspectCodeMSI
    )
  )

//條件5
define "1規則1-5=或錯誤配對修復功能不足性(dMMR)":
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
        and Cdg.code in CodeConcept.inspectCodedMMR
    )
  )

//條件6
define "1規則1-6=成年病人第一線治療":
  Patient.birthDate is not null
  and "是否滿18歲"
  and  exists (
    [Claim] C
      where exists (
        C.item I
          where exists (
            I.modifier M
              where exists (
                M.coding Cdg
                  where Cdg.system in CodeConcept.NHILOT
                    and Cdg.code = '1'
            )
        )
    )
  )

define "1規則1":
  ("1規則1-1" and "1規則1-6=成年病人第一線治療" and "1規則1-3=做為無法切除")
  or "1規則1-4=或轉移性高微衛星不穩定性(MSI-H)" 
  or "1規則1-5=或錯誤配對修復功能不足性(dMMR)"

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
    and (
      (OBs.value is FHIR.integer and (OBs.value as FHIR.integer).value <= 1)
      or (OBs.value is FHIR.Quantity and (OBs.value as FHIR.Quantity).value <= 1)
    )
  )

//條件2
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
    and (OBs.value as FHIR.string).value in { 'Class I', 'Class II', 'class1', 'class2' }
  )

//條件3-1
define "1規則2-3-1=GOT<60U/L及GPT<60U/L":
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
        and (
        Cdg.code in CodeConcept.GOT
        or Cdg.code in CodeConcept.GPT
        )
    )
     and OBs.value is FHIR.Quantity
    and (OBs.value as FHIR.Quantity).value < 60
  )

//條件3-2
define "1規則2-3-2=T-bilirubin<1.5mg/dL":
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
        and Cdg.code in CodeConcept.Tbilirubin
    )
     and OBs.value is FHIR.Quantity
    and (OBs.value as FHIR.Quantity).value < 1.5
  )

define "1規則2-3":
  "1規則2-3-1=GOT<60U/L及GPT<60U/L" and "1規則2-3-2=T-bilirubin<1.5mg/dL"

//條件4-1
define "1規則2-4-1=Creatinine<1.5mg/dL":
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

//條件4-2
define "1規則2-4-2=eGFR>60mL/min/1.73m2":
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
  "1規則2-4-1=Creatinine<1.5mg/dL" and "1規則2-4-2=eGFR>60mL/min/1.73m2"

define "1規則2":
  "1規則2-1=病人身體狀況良好(ECOG≦1)" 
  and "1規則2-2=NYHA(the New York Heart Association) Functional Class I或II" 
  and "1規則2-3"
  and "1規則2-4"


/*規則4*/
//條件1
define "1規則4-1=12週內之疾病影像檢查及報告":
  exists (
    [DiagnosticReport] O
    where exists (
      O.code.coding Cdg
      where (
        Cdg in CodeConcept.ICD10PCS2023Image
        or Cdg in CodeConcept.ICD10PCS2014Image
      )
      and Cdg.code in CodeConcept.PembrolizumabImage
    )
    and O.effective is not null
    and FHIRHelpers.ToDateTime(O.effective) >= "本次申請起始日期" - 84 days
    and FHIRHelpers.ToDateTime(O.effective) <= "本次申請起始日期"
  ) 

define "1規則4-2-使用免疫檢查點抑制劑之治療計畫":
  exists (
    [Claim] C
      where exists (
        C.supportingInfo Cs
          where exists (
            Cs.category.coding coding
              where coding in CodeConcept.NHIPASSupportingInfoType
              and coding.code = 'carePlanDocument'
          )
          and exists (
            [DocumentReference] D
              where (
                (Cs.value as Reference).reference = 'DocumentReference/' + D.id
                or (Cs.value as Reference).reference = D.id
              )
              and exists (
                D.content Content
                  where Content.attachment.title is not null
                    and Matches(Content.attachment.title, '(?i).*免疫檢查點抑制劑治療計畫.*')
              )
          )
      )
  )

define "1規則4":
  "1規則4-1=12週內之疾病影像檢查及報告"
  and "1規則4-2-使用免疫檢查點抑制劑之治療計畫"

define "主要規定一":
  Reusable."初次申請" and
  "1規則1"
  and "1規則2"
  and "1規則4"


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
      and RasObservation.value is not null
      and RasObservation.value is FHIR.string
      and Matches((RasObservation.value as FHIR.string).value, '(?i).*(iPR|iCR|PR|CR).*')
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
    and Matches((RasObservation.value as FHIR.string).value, '(?i).*(iCPD|PD).*')
  )
  and not exists (
    [Claim] C
    where exists (
      C.diagnosis Diag
      where Diag.type.text is not null
        and exists (
          Diag.type.text T
          where Matches(T, '(?i).*中、重度或危及生命之藥物不良反應.*')
        )
    )
  )

//條件3
define "2規則1-3=未出現疾病併發症或輕度藥物不良反應等，或沒有暫停用藥超過原事前審查核定日起24週期限者":
  Reusable."醫令類別為1"
  and not Reusable."HasPriorMedicationGapLongerThan"(CodeConcept.L01FF02, 168)

//條件4
define "2規則1-4-0=SD評估記錄":
  [Observation] RasObservation
    where exists (
      RasObservation.code.coding ObsCodeCoding
        where ObsCodeCoding.code in CodeConcept."IREC疾病狀態評估"
          and ObsCodeCoding in CodeConcept.NHITreatmentAst
    )
    and RasObservation.value is not null
    and RasObservation.value is FHIR.string
    and Matches((RasObservation.value as FHIR.string).value, '(?i).*(iSD|SD).*')

define "2規則1-4-1=檢查是第一次被評估為SD":
  exists "2規則1-4-0=SD評估記錄"
  and singleton from "2規則1-4-0=SD評估記錄" is not null

define "2規則1":
  ("2規則1-1=以i-RECIST標準(HCC患者以mRECIST標準)評定藥物療效反應，依下列原則申請續用：有療效反應(PR及CR)者得繼續用藥"
    or "2規則1-4-1=檢查是第一次被評估為SD")
  and "2規則1-2=未出現疾病惡化(PD)或未出現中、重度或危及生命之藥物不良反應者，應停止用藥"
  and "2規則1-3=未出現疾病併發症或輕度藥物不良反應等，或沒有暫停用藥超過原事前審查核定日起24週期限者"

/*規則2*/
define "2規則2":
  "1規則2" and "1規則4-1=12週內之疾病影像檢查及報告"

define "主要規定二":
  Reusable."續用申請" and
  "2規則1"
  and "2規則2"


//============================================
// 主要規定三：藥品使用規則
//============================================

/*規則1*/
//條件1
define "3規則1-1=病人每個適應症限給付一種免疫檢查點抑制劑且不得互換":
  Reusable."醫令類別為1"
  and not Reusable."HasConcurrentMedicationUse"(CodeConcept.L01FF02, CodeConcept.L01FFexceptL01FF02)

//條件2
define "3規則1-2=治療期間亦不可合併申報該適應症之標靶藥物，無效後或給付時程期滿後則不再給付該適應症相關之標靶藥物":
  Reusable."醫令類別為1"
  and not Reusable."HasConcurrentMedicationUse"(CodeConcept.L01FF02, CodeConcept."CRCTargetedTherapy")

//條件3
define "3規則1-3=總使用療程以2年為上限":
  Reusable."HasMedicationTotalDurationWithin"(CodeConcept.L01FF02, 730)

//條件4
define "3規則1-4=每次申請以12週為限":
  Reusable."HasMedicationPlanDurationWithin"(CodeConcept.L01FF02, 84)

define "主要規定三":
  "3規則1-1=病人每個適應症限給付一種免疫檢查點抑制劑且不得互換"
  and "3規則1-2=治療期間亦不可合併申報該適應症之標靶藥物，無效後或給付時程期滿後則不再給付該適應症相關之標靶藥物"
  and "3規則1-3=總使用療程以2年為上限"
  and "3規則1-4=每次申請以12週為限"


//============================================
// 檢核結果用：必要資料存在判斷
//============================================

define "Pembrolizumab申請資料存在":
  Reusable."HasMedicationPlanRecord"(CodeConcept.L01FF02)

define "給付適應症資料存在":
  exists (
    [Claim] C
    where exists (
      C.item I
      where exists (
        I.programCode PC
        where PC.coding is not null
      )
    )
  )

define "影像報告資料存在":
  Reusable."影像或檢查報告資料存在"

define "無法切除說明資料存在":
  exists (
    [Claim] C
    where exists (
      C.diagnosis Diag
      where Diag.type.text is not null
    )
  )

define "MSI或dMMR檢測資料存在":
  Reusable."HasObservationCode"(CodeConcept.inspectCodeMSI)
  or Reusable."HasObservationCode"(CodeConcept.inspectCodedMMR)

define "ECOG資料存在":
  exists (
    [Observation] O
    where exists (
      O.code.coding Cdg
      where Cdg in CodeConcept.LOINC
        and Cdg.code = '89247-1'
    )
  )

define "NYHA資料存在":
  exists (
    [Observation] O
    where exists (
      O.code.coding Cdg
      where Cdg in CodeConcept.LOINC
        and Cdg.code = '88020-3'
    )
  )

define "肝功能資料存在":
  Reusable."HasObservationCode"(CodeConcept.GOT)
  and Reusable."HasObservationCode"(CodeConcept.GPT)
  and Reusable."HasObservationCode"(CodeConcept.Tbilirubin)

define "腎功能資料存在":
  Reusable."HasObservationCode"(CodeConcept.Creatinine)
  and Reusable."HasObservationCode"(CodeConcept.eGFR)

define "治療計畫資料存在":
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

define "續用療效評估資料存在":
  Reusable."治療反應評估資料存在"

define "療程期間資料存在":
  Reusable."HasMedicationPlanTiming"(CodeConcept.L01FF02)

define "併用免疫或標靶藥品資料存在":
  Reusable."HasMedicationRecord"(CodeConcept.L01FF)
  or Reusable."HasMedicationRecord"(CodeConcept."CRCTargetedTherapy")

define "必要資料皆存在":
  not (
    (Reusable."初次申請" and (
      not "Pembrolizumab申請資料存在"
      or not Reusable."主要疾病ICD診斷資料存在"
      or not "給付適應症資料存在"
      or Patient.birthDate is null
      or not "影像報告資料存在"
      or not "無法切除說明資料存在"
      or not "MSI或dMMR檢測資料存在"
      or not "ECOG資料存在"
      or not "NYHA資料存在"
      or not "肝功能資料存在"
      or not "腎功能資料存在"
      or not "治療計畫資料存在"
    ))
    or (Reusable."續用申請" and (
      not "Pembrolizumab申請資料存在"
      or not "續用療效評估資料存在"
      or not "影像報告資料存在"
      or not "ECOG資料存在"
      or not "NYHA資料存在"
      or not "肝功能資料存在"
      or not "腎功能資料存在"
    ))
    or not "療程期間資料存在"
  )


//============================================
// 列出「符合」項目判斷式
//============================================

define function "符合項目"():
  // 主要規定一：初次使用條件
  (if Reusable."初次申請" and ("1規則1-1" or "1規則1-1-2=三個月內有影像檢查報告" or "1規則1-3=做為無法切除" or "1規則1-4=或轉移性高微衛星不穩定性(MSI-H)" or "1規則1-5=或錯誤配對修復功能不足性(dMMR)" or "1規則1-6=成年病人第一線治療" or "1規則2-1=病人身體狀況良好(ECOG≦1)" or "1規則2-2=NYHA(the New York Heart Association) Functional Class I或II" or "1規則2-3" or "1規則2-4" or "1規則4-1=12週內之疾病影像檢查及報告" or "1規則4-2-使用免疫檢查點抑制劑之治療計畫")
    then '<主要規定一：初次使用條件>\n' +
         (if Reusable."主要疾病之ICD-10使用C18、C19、C20、C21" 
           then '● 規則1-1-1：主要疾病之ICD代碼為C18、C19、C20、C21\n' else '') +
         (if "1規則1-1-2=三個月內有影像檢查報告"
           then '● 規則1-1-2：三個月內有影像檢查報告\n' else '') +
         (if "1規則1-1-3=申請項目" 
           then '● 規則1-1-3：申請項目符合\n' else '') +
         (if "1規則1-3=做為無法切除" 
           then '● 規則1-3：做為無法切除\n' else '') +
         (if "1規則1-4=或轉移性高微衛星不穩定性(MSI-H)" 
           then '● 規則1-4：轉移性高微衛星不穩定性（MSI-H）\n' else '') +
         (if "1規則1-5=或錯誤配對修復功能不足性(dMMR)" 
           then '● 規則1-5：錯誤配對修復功能不足性（dMMR）\n' else '') +
         (if "1規則1-6=成年病人第一線治療" 
           then '● 規則1-6：成年病人第一線治療\n' else '') +
         (if "1規則2-1=病人身體狀況良好(ECOG≦1)" 
           then '● 規則2-1：病人身體狀況良好（ECOG≦1）\n' else '') +
         (if "1規則2-2=NYHA(the New York Heart Association) Functional Class I或II" 
           then '● 規則2-2：NYHA Functional Class I或II\n' else '') +
         (if "1規則2-3-1=GOT<60U/L及GPT<60U/L" 
           then '● 規則2-3-1：GOT<60U/L及GPT<60U/L\n' else '') +
         (if "1規則2-3-2=T-bilirubin<1.5mg/dL" 
           then '● 規則2-3-2：T-bilirubin<1.5mg/dL\n' else '') +
         (if "1規則2-4-1=Creatinine<1.5mg/dL" 
           then '● 規則2-4-1：Creatinine<1.5mg/dL\n' else '') +
         (if "1規則2-4-2=eGFR>60mL/min/1.73m2" 
           then '● 規則2-4-2：eGFR>60mL/min/1.73m2\n' else '') +
         (if "1規則4-1=12週內之疾病影像檢查及報告" 
           then '● 規則4-1：12週內之疾病影像檢查及報告\n' else '') +
         (if "1規則4-2-使用免疫檢查點抑制劑之治療計畫" 
           then '● 規則4-2：使用免疫檢查點抑制劑之治療計畫\n' else '') +
         '\n'  
    else '') +
  
  // 主要規定二：續用條件
  (if Reusable."續用申請" and ("2規則1-1=以i-RECIST標準(HCC患者以mRECIST標準)評定藥物療效反應，依下列原則申請續用：有療效反應(PR及CR)者得繼續用藥" or "2規則1-4-1=檢查是第一次被評估為SD" or "2規則1-2=未出現疾病惡化(PD)或未出現中、重度或危及生命之藥物不良反應者，應停止用藥" or "2規則1-3=未出現疾病併發症或輕度藥物不良反應等，或沒有暫停用藥超過原事前審查核定日起24週期限者" or "1規則2" or "1規則4-1=12週內之疾病影像檢查及報告")
    then '<主要規定二：續用條件－治療持續給付>\n' +
         (if "2規則1-1=以i-RECIST標準(HCC患者以mRECIST標準)評定藥物療效反應，依下列原則申請續用：有療效反應(PR及CR)者得繼續用藥"
           then '● 續用規則1-1：有療效反應（iPR或iCR）\n' else '') +
         (if "2規則1-4-1=檢查是第一次被評估為SD"
           then '● 續用規則1-4：第一次被評估為SD\n' else '') +
         (if "2規則1-2=未出現疾病惡化(PD)或未出現中、重度或危及生命之藥物不良反應者，應停止用藥"
           then '● 續用規則1-2：未出現疾病惡化或嚴重藥物不良反應\n' else '') +
         (if "2規則1-3=未出現疾病併發症或輕度藥物不良反應等，或沒有暫停用藥超過原事前審查核定日起24週期限者"
           then '● 續用規則1-3：未暫停用藥超過24週\n' else '') +
         (if "1規則2"
           then '● 續用規則2：病人身體狀況及實驗室檢查符合\n' else '') +
         (if "1規則4-1=12週內之疾病影像檢查及報告"
           then '● 續用規則2：12週內之疾病影像檢查及報告\n' else '') +
         '\n'  
    else '') +
  
  // 主要規定三：藥品使用規則
  (if "3規則1-1=病人每個適應症限給付一種免疫檢查點抑制劑且不得互換" or "3規則1-2=治療期間亦不可合併申報該適應症之標靶藥物，無效後或給付時程期滿後則不再給付該適應症相關之標靶藥物" or "3規則1-3=總使用療程以2年為上限" or "3規則1-4=每次申請以12週為限"
    then '<主要規定三：藥品使用規則>\n' +
         (if "3規則1-1=病人每個適應症限給付一種免疫檢查點抑制劑且不得互換" 
           then '● 規則3-1：每個適應症限給付一種免疫檢查點抑制劑且不得互換（參考資訊）\n' else '') +
         (if "3規則1-2=治療期間亦不可合併申報該適應症之標靶藥物，無效後或給付時程期滿後則不再給付該適應症相關之標靶藥物" 
           then '● 規則3-2：治療期間不可合併申報標靶藥物（參考資訊）\n' else '') +
         (if "3規則1-3=總使用療程以2年為上限" 
           then '● 規則3-3：總使用療程以2年為上限（參考資訊）\n' else '') +
         (if "3規則1-4=每次申請以12週為限" 
           then '● 規則3-4：每次申請以12週為限（參考資訊）\n' else '')
    else '')

//============================================
// 列出「不符合」項目判斷式 - 條件或代碼不符合
//============================================

define function "不符合項目_條件或代碼不符合"():
  // 主要規定一：初次使用條件 - 代碼條件不符
  (if Reusable."初次申請" and (
    (Reusable."主要疾病ICD診斷資料存在" and not Reusable."主要疾病之ICD-10使用C18、C19、C20、C21")
    or ("給付適應症資料存在" and not "1規則1-1-3=申請項目")
    or (Patient.birthDate is not null and not "1規則1-6=成年病人第一線治療")
    or ("影像報告資料存在" and not ("1規則1-1-2=三個月內有影像檢查報告" and "1規則4-1=12週內之疾病影像檢查及報告"))
    or ("無法切除說明資料存在" and not "1規則1-3=做為無法切除")
    or ("MSI或dMMR檢測資料存在" and not ("1規則1-4=或轉移性高微衛星不穩定性(MSI-H)" or "1規則1-5=或錯誤配對修復功能不足性(dMMR)"))
    or ("ECOG資料存在" and not "1規則2-1=病人身體狀況良好(ECOG≦1)")
    or ("NYHA資料存在" and not "1規則2-2=NYHA(the New York Heart Association) Functional Class I或II")
    or ("肝功能資料存在" and not "1規則2-3")
    or ("腎功能資料存在" and not "1規則2-4")
    or ("治療計畫資料存在" and not "1規則4-2-使用免疫檢查點抑制劑之治療計畫")
  )
    then '<主要規定一：初次使用條件>\n' +
         (if Reusable."主要疾病ICD診斷資料存在" and not Reusable."主要疾病之ICD-10使用C18、C19、C20、C21" 
           then '▲ 規則1-1-1：主要疾病之ICD代碼未使用C18、C19、C20、C21\n' else '') +
         (if "給付適應症資料存在" and not "1規則1-1-3=申請項目"
           then '▲ 規則1-1-3：申請藥物非 Pembrolizumab，或給付適應症非 P141，或非第一線用藥線別\n' else '') +
         (if Patient.birthDate is not null and not "1規則1-6=成年病人第一線治療"
           then '▲ 規則1-6：非成年病人或非第一線治療\n' else '') +
         (if "影像報告資料存在" and not ("1規則1-1-2=三個月內有影像檢查報告" and "1規則4-1=12週內之疾病影像檢查及報告")
           then '▲ 規則1-1-2/4-1：影像報告不在規定時間內或代碼不符合\n' else '') +
         (if "無法切除說明資料存在" and not "1規則1-3=做為無法切除"
           then '▲ 規則1-3：無法切除說明不符合條件\n' else '') +
         (if "MSI或dMMR檢測資料存在" and not ("1規則1-4=或轉移性高微衛星不穩定性(MSI-H)" or "1規則1-5=或錯誤配對修復功能不足性(dMMR)")
           then '▲ 規則1-4/1-5：MSI-H或dMMR檢測結果不符合\n' else '') +
         (if "ECOG資料存在" and not "1規則2-1=病人身體狀況良好(ECOG≦1)" 
           then '▲ 規則2-1：病人身體狀況不佳（非ECOG≦1）\n' else '') +
         (if "NYHA資料存在" and not "1規則2-2=NYHA(the New York Heart Association) Functional Class I或II" 
           then '▲ 規則2-2：NYHA Functional Class非I或II\n' else '') +
         (if "肝功能資料存在" and (not "1規則2-3-1=GOT<60U/L及GPT<60U/L" or not "1規則2-3-2=T-bilirubin<1.5mg/dL")
           then '▲ 規則2-3：肝功能檢查不符合標準\n' +
                (if not "1規則2-3-1=GOT<60U/L及GPT<60U/L"
                  then '  - GOT或GPT非<60U/L\n' else '') +
                (if not "1規則2-3-2=T-bilirubin<1.5mg/dL"
                  then '  - T-bilirubin非<1.5mg/dL\n' else '')
           else '') +
         (if "腎功能資料存在" and (not "1規則2-4-1=Creatinine<1.5mg/dL" or not "1規則2-4-2=eGFR>60mL/min/1.73m2")
           then '▲ 規則2-4：腎功能檢查不符合標準\n' +
                (if not "1規則2-4-1=Creatinine<1.5mg/dL"
                  then '  - Creatinine非<1.5mg/dL\n' else '') +
                (if not "1規則2-4-2=eGFR>60mL/min/1.73m2"
                  then '  - eGFR非>60mL/min/1.73m2\n' else '')
           else '') +
         '\n'  
    else '') +

  // 主要規定二：續用條件 - 代碼條件不符
  (if Reusable."續用申請" and (
    ("續用療效評估資料存在" and not "2規則1")
    or ("影像報告資料存在" and not "1規則4-1=12週內之疾病影像檢查及報告")
    or ("ECOG資料存在" and not "1規則2-1=病人身體狀況良好(ECOG≦1)")
    or ("NYHA資料存在" and not "1規則2-2=NYHA(the New York Heart Association) Functional Class I或II")
    or ("肝功能資料存在" and (not "1規則2-3-1=GOT<60U/L及GPT<60U/L" or not "1規則2-3-2=T-bilirubin<1.5mg/dL"))
    or ("腎功能資料存在" and (not "1規則2-4-1=Creatinine<1.5mg/dL" or not "1規則2-4-2=eGFR>60mL/min/1.73m2"))
  )
    then '<主要規定二：續用條件－治療持續給付>\n' +
         '▲ 續用規則2：病人身體狀況檢查不符\n' +
         (if not "1規則2-1=病人身體狀況良好(ECOG≦1)" 
           then '  - 病人身體狀況不佳（非ECOG≦1）\n' else '') +
         (if not "1規則2-2=NYHA(the New York Heart Association) Functional Class I或II" 
           then '  - NYHA Functional Class非I或II\n' else '') +
         (if not "1規則2-3-1=GOT<60U/L及GPT<60U/L" or not "1規則2-3-2=T-bilirubin<1.5mg/dL"
           then '  - 肝功能檢查不符合標準\n' +
                (if not "1規則2-3-1=GOT<60U/L及GPT<60U/L"
                  then '    · GOT或GPT非<60U/L\n' else '') +
                (if not "1規則2-3-2=T-bilirubin<1.5mg/dL"
                  then '    · T-bilirubin非<1.5mg/dL\n' else '')
           else '') +
         (if not "1規則2-4-1=Creatinine<1.5mg/dL" or not "1規則2-4-2=eGFR>60mL/min/1.73m2"
           then '  - 腎功能檢查不符合標準\n' +
                (if not "1規則2-4-1=Creatinine<1.5mg/dL"
                  then '    · Creatinine非<1.5mg/dL\n' else '') +
                (if not "1規則2-4-2=eGFR>60mL/min/1.73m2"
                  then '    · eGFR非>60mL/min/1.73m2\n' else '')
           else '') +
         '\n'  
    else '') +
  
  // 主要規定三：藥品使用規則 - 代碼條件不符
  (if ("併用免疫或標靶藥品資料存在" and (not "3規則1-1=病人每個適應症限給付一種免疫檢查點抑制劑且不得互換" or not "3規則1-2=治療期間亦不可合併申報該適應症之標靶藥物，無效後或給付時程期滿後則不再給付該適應症相關之標靶藥物")) or ("療程期間資料存在" and (not "3規則1-3=總使用療程以2年為上限" or not "3規則1-4=每次申請以12週為限"))
    then '<主要規定三：藥品使用規則>\n' +
         (if not "3規則1-1=病人每個適應症限給付一種免疫檢查點抑制劑且不得互換" 
           then '▲ 規則3-1：同一適應症下已使用其他免疫檢查點抑制劑，不得再申請或更換用藥（參考資訊）\n' else '') +
         (if not "3規則1-2=治療期間亦不可合併申報該適應症之標靶藥物，無效後或給付時程期滿後則不再給付該適應症相關之標靶藥物" 
           then '▲ 規則3-2：治療期間不得合併申報該適應症之標靶藥物；治療無效或給付時程期滿後，亦不得再申請該適應症相關標靶藥物（參考資訊）\n' else '') +
         (if not "3規則1-3=總使用療程以2年為上限" 
           then '▲ 規則3-3：總使用療程超過2年上限（參考資訊）\n' else '') +
         (if not "3規則1-4=每次申請以12週為限" 
           then '▲ 規則3-4：每次申請超過12週限制（參考資訊）\n' else '')
    else '')

//============================================
// 列出「不符合」項目判斷式 - 必要資料未填寫
//============================================

define function "不符合項目_必要資料未填寫"():
  // 主要規定一：初次使用條件 - 必要資料未填寫
  (if Reusable."初次申請" and (
    not "Pembrolizumab申請資料存在"
    or not Reusable."主要疾病ICD診斷資料存在"
    or not "給付適應症資料存在"
    or Patient.birthDate is null
    or not "影像報告資料存在"
    or not "無法切除說明資料存在"
    or not "MSI或dMMR檢測資料存在"
    or not "ECOG資料存在"
    or not "NYHA資料存在"
    or not "肝功能資料存在"
    or not "腎功能資料存在"
    or not "治療計畫資料存在"
  )
    then '<主要規定一：初次使用條件>\n' +
         (if not "Pembrolizumab申請資料存在" then '▲ 申請醫令：未提供Pembrolizumab申請醫令資料\n' else '') +
         (if not Reusable."主要疾病ICD診斷資料存在" then '▲ 規則1-1-1：未提供主要疾病ICD診斷資料\n' else '') +
         (if not "給付適應症資料存在" then '▲ 規則1-1-3：未提供給付適應症或線別資料\n' else '') +
         (if Patient.birthDate is null then '▲ 規則1-6：未提供出生日期，無法判定是否成年\n' else '') +
         (if not "影像報告資料存在" then '▲ 規則1-1-2/4-1：未提供影像檢查報告\n' else '') +
         (if not "無法切除說明資料存在" then '▲ 規則1-3：未提供無法切除說明\n' else '') +
         (if not "MSI或dMMR檢測資料存在" then '▲ 規則1-4/1-5：未提供MSI-H或dMMR檢測資料\n' else '') +
         (if not "ECOG資料存在" then '▲ 規則2-1：未提供ECOG資料\n' else '') +
         (if not "NYHA資料存在" then '▲ 規則2-2：未提供NYHA資料\n' else '') +
         (if not "肝功能資料存在" then '▲ 規則2-3：未提供完整肝功能檢查資料\n' else '') +
         (if not "腎功能資料存在" then '▲ 規則2-4：未提供完整腎功能檢查資料\n' else '') +
         (if not "治療計畫資料存在" then '▲ 規則4-2：未提供免疫檢查點抑制劑之治療計畫\n' else '') +
         '\n'  
    else '') +
  
  // 主要規定二：續用條件 - 必要資料未填寫
  (if Reusable."續用申請" and (
    not "Pembrolizumab申請資料存在"
    or not "續用療效評估資料存在"
    or not "影像報告資料存在"
    or not "ECOG資料存在"
    or not "NYHA資料存在"
    or not "肝功能資料存在"
    or not "腎功能資料存在"
  )
    then '<主要規定二：續用條件－治療持續給付>\n' +
         (if not "Pembrolizumab申請資料存在" then '▲ 申請醫令：未提供Pembrolizumab申請醫令資料\n' else '') +
         (if not "續用療效評估資料存在" then '▲ 續用規則1：未提供療效評估資料\n' else '') +
         (if not "影像報告資料存在" then '▲ 續用規則2：未提供12週內之疾病影像檢查及報告\n' else '') +
         (if not "ECOG資料存在" then '▲ 續用規則2：未提供ECOG資料\n' else '') +
         (if not "NYHA資料存在" then '▲ 續用規則2：未提供NYHA資料\n' else '') +
         (if not "肝功能資料存在" then '▲ 續用規則2：未提供完整肝功能檢查資料\n' else '') +
         (if not "腎功能資料存在" then '▲ 續用規則2：未提供完整腎功能檢查資料\n' else '') +
         '\n'  
    else '') +

  (if not "療程期間資料存在"
    then '<主要規定三：藥品使用規則>\n' +
         '▲ 規則3-3/3-4：未提供療程起迄日期資料（參考資訊）\n' +
         '\n'
    else '')

//============================================
// 審核結果
//============================================

define "大腸直腸癌Pembrolizumab申請結果_布林":
  case
    when Reusable."初次申請" then (
      "1規則1" and
      "1規則2" and
      "1規則4"
    )
    when Reusable."續用申請" then (
      "2規則1" and
      "2規則2"
    )
    else false
  end

define "大腸直腸癌Pembrolizumab申請結果":
  if (
    Reusable."初次申請" and 
    "1規則1" and
    "1規則2" and
    "1規則4"
  )
  then '✓通過：初次使用－大腸直腸癌 Pembrolizumab 用藥申請'
  else if (
    Reusable."續用申請" and
    "2規則1" and
    "2規則2"
  )
  then '✓通過：續用－大腸直腸癌 Pembrolizumab 用藥申請'
  else if Reusable."初次申請"
  then '✖不通過：初次使用－大腸直腸癌 Pembrolizumab 用藥申請'
  else if Reusable."續用申請"
  then '✖不通過：續用－大腸直腸癌 Pembrolizumab 用藥申請'
  else '✖不通過：無法判定申請類型－大腸直腸癌 Pembrolizumab 用藥申請'

//============================================
// 審核報告總結
//============================================

define "報告總結":
  '\n=== 大腸直腸癌之Pembrolizumab(一線治療) 申請審核報告 ===\n' +
  '\n※ 備註：標示為「參考資訊」之檢核項目，係供審核參酌使用，不作為最終【申請結果】判定之依據。\n' +
  '\n【申請類型】' + Reusable."申請類型" + '\n' +
  '\n【●符合項目】\n' +
  (if "符合項目"() = '' then '無\n' else "符合項目"()) +
  '\n【▲不符合項目 - 必要資料未填寫】\n' +
  (if "不符合項目_必要資料未填寫"() = '' then '無\n' else "不符合項目_必要資料未填寫"()) +
  '\n【▲不符合項目 - 條件或代碼不符合】\n' +
  (if "不符合項目_條件或代碼不符合"() = '' then '無\n' else "不符合項目_條件或代碼不符合"()) +
  '\n【申請結果】\n' +
  "大腸直腸癌Pembrolizumab申請結果" +
  '\n===============================================\n'
