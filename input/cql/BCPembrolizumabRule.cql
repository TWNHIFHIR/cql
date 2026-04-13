//早期三陰性乳癌_Pembrolizumab給付規定

library BCPembrolizumabRule version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

include BCCodeConcept version '1.0.0' called CodeConcept

include BCReusable version '1.0.0' called Reusable

context Patient



//============================================
// 主要規定一：初次使用條件
//============================================

/*規則1*/
//本類藥品得於藥品許可證登載之適應症及藥品仿單內，併用其他藥品於下列患者：
//(7)早期三陰性乳癌：非轉移性、第II期至第IIIb期（cT1c N1-2 或 T2-4 N0-2）成年病人(114/6/1)
define "本次申請紀錄":
  Reusable."LatestMedicationPlan"(CodeConcept.L01FF02)


//1條件1:早期三陰性乳癌
define "ICD代碼檢核_布林值": Reusable."ICD-10使用C50"

define "用藥線別檢核_布林值": Reusable."用藥線別=1"

define "病摘早期三陰性乳癌":
    exists (
        [Claim] C
        where exists (
            C.diagnosis D
            where exists (
                D.type.text T
                where Matches(T.value, '(?i).*(早期三陰性乳癌).*')
            )
        )
    )

define "給付適應症條件P131":
  exists (
    [Claim] C
      where exists (
        C.item I
          where exists (
            I.programCode PC
              where exists (
                PC.coding Cdg
                  where Cdg in CodeConcept.NHIApplyReason
                  and Cdg.code = 'P131'
              )
          )
      )
  )


define "1條件1=早期三陰性乳癌":
Reusable."ICD-10使用C50"
and "病摘早期三陰性乳癌"
and "給付適應症條件P131"
and Reusable."ICD-10使用C50"
and Reusable."用藥線別=1"
and "本次申請紀錄" is not null


//1條件2:非轉移性、第II期至第IIIb期（cT1c N1-2 或 T2-4 N0-2）
//M=0 (pT4aN2bM1a) and if cT1c then N1-2 else  T2-4 then N0-2
define "1條件2=非轉移性、第II期至第IIIb期（cT1c N1-2 或 T2-4 N0-2）":
  exists (
    [Observation] O
      where exists (
        O.code.coding Cdg
          where Cdg.code = '399390009'
            and Cdg in CodeConcept.SNOMED
      )
        and O.value is not null
        and O.value is FHIR.string
        and (
          Matches((O.value as FHIR.string).value, '.*M0.*')
          or Matches((O.value as FHIR.string).value, '.*pT4aN2bM1a.*')
        )
        and (
          if Matches((O.value as FHIR.string).value, '.*cT1c.*')
            then Matches((O.value as FHIR.string).value, '.*N[1-2](?![0-9]).*')
          else
            Matches((O.value as FHIR.string).value, '.*[cpy]?T[2-4][a-z]?.*')
            and Matches((O.value as FHIR.string).value, '.*N[0-2](?![0-9]).*')
        )
  )

//1條件3:成年
define "本次申請起始日期":
  Reusable."GetStartTime"("本次申請紀錄")

define "本次申請結束日期":
  Reusable."GetEndTime"("本次申請紀錄")

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


define "1條件3=成年(>=18y)":
  Patient.birthDate is not null
  and "是否滿18歲"


define "一規則1":
"1條件1=早期三陰性乳癌"
and "1條件2=非轉移性、第II期至第IIIb期（cT1c N1-2 或 T2-4 N0-2）"
and "1條件3=成年(>=18y)"

/*規則2*/
//術前前導性治療：限pembrolizumab每3週1次與carboplatin和paclitaxel併用至多4個療程
//(useSdate between sDate and eDate) and (useEdate between sDate and eDate)與申請藥品併用(L01FF02)
//useEdate-useSdate<84days

define "術前前導性_Carboplatin":
  [MedicationRequest] MR
    where MR.intent = 'plan'
      and exists (
        MR.medication.coding Cdg
          where Cdg in CodeConcept.NHIMedication
            and Cdg.code in CodeConcept.L01XA02
      )
      and Reusable."HasValidTiming"(MR)

define "術前前導性_Paclitaxel":
  [MedicationRequest] MR
    where MR.intent = 'plan'
      and exists (
        MR.medication.coding Cdg
          where Cdg in CodeConcept.NHIMedication
            and Cdg.code in CodeConcept.L01CD01
      )
      and Reusable."HasValidTiming"(MR)

define "一規則2=術前前導性治療併用Carboplatin和Paclitaxel且至多4個療程":
  "本次申請紀錄" is not null
  and exists (
    "術前前導性_Carboplatin" MRC
      where
        // carboplatin 用藥區間在 pembrolizumab 申請區間內
        Reusable."GetStartTime"(MRC) >= "本次申請起始日期"
        and Reusable."GetEndTime"(MRC) <= "本次申請結束日期"
        // 療程總天數 < 84 天（至多4個療程 × 21天）
        and (difference in days between Reusable."GetStartTime"(MRC) and Reusable."GetEndTime"(MRC)) < 84
        // paclitaxel 在申請區間內（與 carboplatin 同屬同一療程區間）
        and exists (
          "術前前導性_Paclitaxel" MRP
            where Reusable."GetStartTime"(MRP) >= "本次申請起始日期"
              and Reusable."GetEndTime"(MRP) <= "本次申請結束日期"
        )
  )

/*規則3*/  

//3條件1:病人身體狀況良好(ECOG≦1)
define "3條件1=病人身體狀況良好(ECOG≦1)":
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
    and (OBs.value as FHIR.integer) <= 1
  )

//3條件2:NYHA(the New York Heart Association) Functional Class I或II
define "3條件2=NYHA(the New York Heart Association) Functional Class I或II":
  exists (
    [Observation] OBs
    where exists (
      OBs.code.coding Cdg
      where Cdg.system in CodeConcept.NHIPASSupportingInfoType
        and Cdg.code = 'patientAssessment'
    )
    and exists (
      OBs.code.coding Cdg
      where Cdg in CodeConcept.LOINC
        and Cdg.code = '88020-3'
    )
    and OBs.value is String
    and (OBs.value = 'Class I' or OBs.value= 'Class II')
  )

//3條件3:GOT<60U/L及GPT<60U/L
define "3條件3=GOT<60U/L及GPT<60U/L":
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
        and Cdg.code in CodeConcept.GOT
        and Cdg.code in CodeConcept.GPT
    )
     and OBs.value is Quantity
    and OBs.value < 60
  )

//3條件4:T-bilirubin<1.5mg/dL
define "3條件4=T-bilirubin<1.5mg/dL":
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
     and OBs.value is Quantity
    and OBs.value < 1.5
  )

//3條件5:Creatinine<1.5mg/dL
define "3條件5=Creatinine<1.5mg/dL":
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
     and OBs.value is Quantity
    and OBs.value < 1.5
  )

//3條件6:eGFR>60mL/min/1.73m2
define "3條件6=eGFR>60mL/min/1.73m2":
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
     and OBs.value is Quantity
    and OBs.value > 60
  )

define "一規則3":
"3條件1=病人身體狀況良好(ECOG≦1)"
and "3條件2=NYHA(the New York Heart Association) Functional Class I或II"
and "3條件3=GOT<60U/L及GPT<60U/L"
and "3條件4=T-bilirubin<1.5mg/dL"
and "3條件5=Creatinine<1.5mg/dL"
and "3條件6=eGFR>60mL/min/1.73m2"

/*規則4*/

//4條件1:IV.病人12週內之疾病影像檢查及報告(如胸部X光、電腦斷層或其他可作為評估的影像)，此影像證明以可測量(measurable)的病灶為優先，如沒有可以測量的病灶，則可評估(evaluable)的病灶亦可採用。
//備註：上述影像檢查之給付範圍不包括正子造影(PET)。
define "4條件1=病人12週內之疾病影像檢查及報告":
Reusable."HasRecentImageReport"("本次申請起始日期", 90)


//4條件2:V.先前已接受過之治療與完整用藥資料(如化學治療、標靶藥物及自費等用藥之劑量及療程)及其治療結果；典型何杰金氏淋巴瘤患者需另檢附自體造血幹細胞移植之病歷紀錄；肝細胞癌患者需另檢附T.A.C.E.治療紀錄。

//4條件3:VI.使用免疫檢查點抑制劑之治療計畫(treatment protocol)
define "4條件3=使用免疫檢查點抑制劑之治療計畫":
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


//4條件4:使用於早期三陰性乳癌用藥時，初次申請時需檢附ER、PR及HER2為陰性之檢測報告
define "檢驗檢查-ER陰性":
  Reusable."HasMarkerNegativeWithGeneLoincTest"(CodeConcept.MolecularER)

define "基因檢測-ER陰性":
  Reusable."HasMarkerNegativeWithGeneLoincGene"(CodeConcept.MolecularER)

define "ER陰性":
  "檢驗檢查-ER陰性" or "基因檢測-ER陰性"

//條件5-2
define "檢驗檢查-PR陰性":
  Reusable."HasMarkerNegativeWithGeneLoincTest"(CodeConcept.MolecularPR)

define "基因檢測-PR陰性":
  Reusable."HasMarkerNegativeWithGeneLoincGene"(CodeConcept.MolecularPR)

define "PR陰性":
  "檢驗檢查-PR陰性" or "基因檢測-PR陰性"

define "HER-2檢測為陰性":
  Reusable."HasHER2NegativeOrND"


define "4條件4=使用於早期三陰性乳癌用藥時，初次申請時需檢附ER、PR及HER2為陰性之檢測報告":
"ER陰性" and "PR陰性" and "HER-2檢測為陰性"

define "一規則4":
"4條件1=病人12週內之疾病影像檢查及報告"
and "4條件3=使用免疫檢查點抑制劑之治療計畫"
and  "4條件4=使用於早期三陰性乳癌用藥時，初次申請時需檢附ER、PR及HER2為陰性之檢測報告"

//主要規定一
define "主要規定一":
"一規則1" 
and "一規則2=術前前導性治療併用Carboplatin和Paclitaxel且至多4個療程"
and "一規則3"
and "一規則4"


//============================================
// 主要規定三：藥品使用規則
//============================================

/*規則1*/

//規則1:接續限pembrolizumab每3週1次與cyclophosphamide和doxorubicin或epirubicin併用至多4個療程，做為初診斷病人前導性治療用藥
define "前導性治療_Cyclophosphamide":
  [MedicationRequest] MR
    where MR.intent = 'plan'
      and exists (
        MR.medication.coding Cdg
          where Cdg in CodeConcept.NHIMedication
            and Cdg.code in CodeConcept.L01AA01
      )
      and Reusable."HasValidTiming"(MR)

define "前導性治療_DoxorubicinOrEpirubicin":
  [MedicationRequest] MR
    where MR.intent = 'plan'
      and exists (
        MR.medication.coding Cdg
          where Cdg in CodeConcept.NHIMedication
            and (
              Cdg.code in CodeConcept.L01DB01
              or Cdg.code in CodeConcept.L01DB03
            )
      )
      and Reusable."HasValidTiming"(MR)

define "二規則1=接續限pembrolizumab每3週1次與cyclophosphamide和doxorubicin或epirubicin併用至多4個療程，做為初診斷病人前導性治療用藥":
  "本次申請紀錄" is not null
  and exists (
    "前導性治療_Cyclophosphamide" MRC
      where
        // cyclophosphamide 用藥區間在 pembrolizumab 申請區間內
        Reusable."GetStartTime"(MRC) >= "本次申請起始日期"
        and Reusable."GetEndTime"(MRC) <= "本次申請結束日期"
        // 療程總天數 < 84 天（至多4個療程 × 21天）
        and (difference in days between Reusable."GetStartTime"(MRC) and Reusable."GetEndTime"(MRC)) < 84
        // doxorubicin 或 epirubicin 在申請區間內（與 cyclophosphamide 同屬同一療程區間）
        and exists (
          "前導性治療_DoxorubicinOrEpirubicin" MRDE
            where Reusable."GetStartTime"(MRDE) >= "本次申請起始日期"
              and Reusable."GetEndTime"(MRDE) <= "本次申請結束日期"
        )
  )

/*規則2*/

//2條件1:手術後未達pCR者
define "2條件1=手術後未達pCR者":
  exists (
    [DiagnosticReport] O2
      where exists (
        O2.code.coding Cdg
          where Cdg in CodeConcept.LOINC
            and Cdg.code in CodeConcept.pALNReport
      )
      and O2.conclusion is not null
      and Matches(O2.conclusion, '(?i).*(手術後未達pCR者).*')
  )
  or exists (
    [Claim] C
    where exists (
        C.diagnosis D
        where exists (
            D.type.text T
            where Matches(T.value, '(?i).*(手術後未達pCR者).*')
          )
      )
  )

//2條件2:單用pembrolizumab每3週1次，做為輔助治療用藥，且至多使用9個療程
define "2條件2=單用pembrolizumab每3週1次，做為輔助治療用藥，且至多使用9個療程":
  "本次申請紀錄" is not null
  and exists (
    [MedicationRequest] MR
      where MR.intent = 'plan'
        and exists (
          MR.medication.coding Cdg
            where Cdg in CodeConcept.NHIMedication
              and Cdg.code in CodeConcept.L01FF02
        )
        and Reusable."HasValidTiming"(MR)
        // 用藥區間在申請區間內
        and Reusable."GetStartTime"(MR) >= "本次申請起始日期"
        and Reusable."GetEndTime"(MR) <= "本次申請結束日期"
        // 療程總天數 < 189 天（至多9個療程 × 21天）
        and (difference in days between Reusable."GetStartTime"(MR) and Reusable."GetEndTime"(MR)) < 189
  )

define "二規則2":
"2條件1=手術後未達pCR者"
and "2條件2=單用pembrolizumab每3週1次，做為輔助治療用藥，且至多使用9個療程"


/*規則3*/
// V.使用於早期三陰性乳癌，術前前導性治療腫瘤惡化(PD)者，或術後輔助治療復發者，不得申請續用

//3條件1
define "3條件1=疾病評估狀態":
  exists (
    [Observation] RasObservation
      where exists (
        RasObservation.code.coding ObsCodeCoding
          where ObsCodeCoding.code in CodeConcept."IREC疾病狀態評估"
            and ObsCodeCoding in CodeConcept.NHITreatmentAst
      )
      and RasObservation.effective is not null
      and FHIRHelpers.ToDateTime(RasObservation.effective as FHIR.dateTime) >= "本次申請起始日期" - 84 days
      and FHIRHelpers.ToDateTime(RasObservation.effective as FHIR.dateTime) <= "本次申請起始日期"
      and RasObservation.value is not null
      and RasObservation.value is FHIR.string
      and Matches((RasObservation.value as FHIR.string).value, '(?i).*(iPD).*')
  )

//3條件2
define "3條件2=6個月內影像報告":
Reusable."HasRecentImageReport"("本次申請起始日期", 180)

define "二規則3=使用於早期三陰性乳癌，術前前導性治療腫瘤惡化(PD)者，或術後輔助治療復發者，不得申請續用":
  "3條件1=疾病評估狀態"


/*規則4*/
//條件1~4同 一規則3

define "二規則4":
"一規則3" and "3條件2=6個月內影像報告"


//主要規定二
define "主要規定二":
Reusable."續用註記為2"
and Reusable."醫令類別為1"
and "本次申請紀錄" is not null
and ("二規則1=接續限pembrolizumab每3週1次與cyclophosphamide和doxorubicin或epirubicin併用至多4個療程，做為初診斷病人前導性治療用藥"
or "二規則2")
and not "二規則3=使用於早期三陰性乳癌，術前前導性治療腫瘤惡化(PD)者，或術後輔助治療復發者，不得申請續用"
and "二規則4"


//============================================
// 主要規定三：藥品使用規則
//============================================

/*規則1*/
//上述pembrolizumab用於早期三陰性乳癌依前述療程規定至多使用17個療程，且用於術後輔助治療，pembrolizumab與olaparib僅能擇一支付。

//1條件1:pembrolizumab用於早期三陰性乳癌依前述療程規定至多使用17個療程，
define "1條件1=pembrolizumab用於早期三陰性乳癌依前述療程規定至多使用17個療程":
  Reusable."HasMedicationPlanDurationWithin"(CodeConcept.L01FF02, 357)

//1條件2:且用於術後輔助治療，pembrolizumab與olaparib僅能擇一支付
define "1條件2=且用於術後輔助治療，pembrolizumab與olaparib僅能擇一支付":
  Reusable."HasMedicationUse"(CodeConcept.L01FF02)
  and Reusable."HasMedicationUse"(CodeConcept.L01XK01)

define "三規則1=pembrolizumab用於早期三陰性乳癌依前述療程規定至多使用17個療程，且用於術後輔助治療，pembrolizumab與olaparib僅能擇一支付":
"1條件1=pembrolizumab用於早期三陰性乳癌依前述療程規定至多使用17個療程" 
and not "1條件2=且用於術後輔助治療，pembrolizumab與olaparib僅能擇一支付"

/*規則2*/
//(4)每位病人每個適應症限給付一種免疫檢查點抑制劑且不得互換，治療期間亦不可合併申報該適應症之標靶藥物（atezolizumab與bevacizumab併用於晚期肝細胞癌第一線用藥除外），無效後或給付時程期滿後則不再給付該適應症相關之標靶藥物。（enfortumab vedotin用於局部晚期或轉移性泌尿道上皮癌第三線用藥除外 ）

//2條件1-1:每位病人每個適應症限給付一種免疫檢查點抑制劑且不得互換
define "ICD-10使用C34":
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
              and Substring(Cdg.code, 0, 3) = 'C34'
          )
      )
  )

define "L01FFexceptL01FF02申請紀錄":
  Reusable."HasMedicationUse"(CodeConcept.L01FFexceptL01FF02)


define "2條件1-1-1":
"ICD-10使用C34" and "本次申請紀錄" is not null

define "2條件1-1-2":
"ICD-10使用C34" and "L01FFexceptL01FF02申請紀錄"

define "2條件1-1=每位病人每個適應症限給付一種免疫檢查點抑制劑且不得互換":
  not ("2條件1-1-1" and "2條件1-1-2")


//2條件1-2:治療期間亦不可合併申報該適應症之標靶藥物
// 涵蓋：L01FD(01-04), L01EH01, L01EF(01-03), L01EG02, L01XK(01/04), L01FX17

define "2條件1-2=治療期間合併申報標靶藥物":
  Reusable."HasConcurrentMedicationPlan"(CodeConcept.L01FF02, CodeConcept."適應症之標靶藥物")

define "三規則2":
"2條件1-1=每位病人每個適應症限給付一種免疫檢查點抑制劑且不得互換"
and not "2條件1-2=治療期間合併申報標靶藥物"


/*規則3*/
//自初次處方用藥日起17個療程
define "規則3=自初次處方用藥日起17個療程":
"1條件1=pembrolizumab用於早期三陰性乳癌依前述療程規定至多使用17個療程"

/*規則4*/
//每次申請以12週為限
define "每次申請以12週為限":
  Reusable."HasMedicationPlanDurationWithin"(CodeConcept.L01FF02, 84)

//主要規定三
define "主要規定三":
  "三規則1=pembrolizumab用於早期三陰性乳癌依前述療程規定至多使用17個療程，且用於術後輔助治療，pembrolizumab與olaparib僅能擇一支付"
  and "三規則2"
  and "每次申請以12週為限"


//============================================
// 列出「符合」項目判斷式
//============================================

define function "符合項目"():
  // 主要規定一：初次使用條件
  (if Reusable."初次申請" and "主要規定一"
    then '<主要規定一：初次使用條件>\n' +
         (if "1條件1=早期三陰性乳癌"
           then '● 條件1：ICD C50、病摘早期三陰性乳癌、給付適應症P131、用藥線別=1\n' else '') +
         (if "1條件2=非轉移性、第II期至第IIIb期（cT1c N1-2 或 T2-4 N0-2）"
           then '● 條件2：非轉移性(M0)、第II期至第IIIb期(cT1c N1-2 或 T2-4 N0-2)\n' else '') +
         (if "1條件3=成年(>=18y)"
           then '● 條件3：成年病人(年齡≥18歲)\n' else '') +
         (if "一規則2=術前前導性治療併用Carboplatin和Paclitaxel且至多4個療程"
           then '● 規則2：術前前導性治療併用carboplatin及paclitaxel，療程≤84天(至多4療程)\n' else '') +
         (if "一規則3"
           then '● 規則3：ECOG≦1、NYHA I/II、GOT/GPT<60、T-bilirubin<1.5、Creatinine<1.5、eGFR>60\n' else '') +
         (if "4條件1=病人12週內之疾病影像檢查及報告"
           then '● 條件4-1：12週內具疾病影像檢查及報告\n' else '') +
         (if "4條件3=使用免疫檢查點抑制劑之治療計畫"
           then '● 條件4-3：已檢附免疫檢查點抑制劑治療計畫\n' else '') +
         (if "4條件4=使用於早期三陰性乳癌用藥時，初次申請時需檢附ER、PR及HER2為陰性之檢測報告"
           then '● 條件4-4：ER陰性、PR陰性、HER2陰性報告\n' else '') +
         '\n'
    else '') +

  // 主要規定二：續用條件
  (if Reusable."續用申請" and "主要規定二"
    then '<主要規定二：續用條件>\n' +
         (if "二規則1=接續限pembrolizumab每3週1次與cyclophosphamide和doxorubicin或epirubicin併用至多4個療程，做為初診斷病人前導性治療用藥"
           then '● 規則1：併用cyclophosphamide及doxorubicin/epirubicin前導性治療，療程≤84天(至多4療程)\n' else '') +
         (if "二規則2"
           then '● 規則2：手術後未達pCR，單用pembrolizumab輔助治療，療程≤189天(至多9療程)\n' else '') +
         (if not "3條件1=疾病評估狀態"
           then '● 規則3：無術前前導性治療腫瘤惡化(PD)或術後輔助治療復發紀錄\n' else '') +
         (if "二規則4"
           then '● 規則4：ECOG/NYHA/肝腎功能符合條件，且具6個月內影像報告\n' else '') +
         '\n'
    else '') +

  // 主要規定三：藥品使用規則
  (if "主要規定三"
    then '<主要規定三：藥品使用規則>\n' +
         (if "1條件1=pembrolizumab用於早期三陰性乳癌依前述療程規定至多使用17個療程"
           then '● 規則1-1：pembrolizumab累計療程符合17個療程上限(≤357天)\n' else '') +
         (if not "1條件2=且用於術後輔助治療，pembrolizumab與olaparib僅能擇一支付"
           then '● 規則1-2：未與olaparib同時申請\n' else '') +
         (if "2條件1-1=每位病人每個適應症限給付一種免疫檢查點抑制劑且不得互換"
           then '● 規則2-1：未同時申請其他免疫檢查點抑制劑\n' else '') +
         (if not "2條件1-2=治療期間合併申報標靶藥物"
           then '● 規則2-2：治療期間未合併申報標靶藥物\n' else '') +
         (if "每次申請以12週為限"
           then '● 規則4：本次申請期間≤12週(84天)\n' else '') +
         '\n'
    else '')


//============================================
// 列出「不符合」項目判斷式 - 代碼或條件不符
//============================================

define function "不符合項目_代碼或條件不符"():
  // 主要規定一：初次使用條件 - 代碼條件不符
  (if Reusable."初次申請" and (
    not Reusable."ICD-10使用C50" or
    not "病摘早期三陰性乳癌" or
    not "給付適應症條件P131" or
    not Reusable."用藥線別=1" or
    not "1條件2=非轉移性、第II期至第IIIb期（cT1c N1-2 或 T2-4 N0-2）" or
    not "1條件3=成年(>=18y)"
  )
    then '<主要規定一：初次使用條件>\n' +
         (if not Reusable."ICD-10使用C50"
           then '▲ ICD代碼：主要疾病ICD代碼未使用C50\n' else '') +
         (if not "病摘早期三陰性乳癌"
           then '▲ 條件1：病摘未記載早期三陰性乳癌\n' else '') +
         (if not "給付適應症條件P131"
           then '▲ 條件1：給付適應症未填寫P131\n' else '') +
         (if not Reusable."用藥線別=1"
           then '▲ 條件1：用藥線別非第一線\n' else '') +
         (if not "1條件2=非轉移性、第II期至第IIIb期（cT1c N1-2 或 T2-4 N0-2）"
           then '▲ 條件2：癌症分期不符(非M0、或非cT1c N1-2、或非T2-4 N0-2)\n' else '') +
         (if not "1條件3=成年(>=18y)"
           then '▲ 條件3：病人未滿18歲\n' else '') +
         '\n'
    else '') +

  // 主要規定二：續用條件 - 不符
  (if Reusable."續用申請" and "3條件1=疾病評估狀態"
    then '<主要規定二：續用條件>\n' +
         '▲ 規則3：疾病評估有腫瘤惡化(PD)或復發紀錄，不得申請續用\n' + '\n'
    else '') +

  // 主要規定三：條件不符
  (if not "1條件1=pembrolizumab用於早期三陰性乳癌依前述療程規定至多使用17個療程"
    then '<主要規定三：藥品使用規則>\n' +
         '▲ 規則1-1：pembrolizumab累計療程超過17個療程上限(357天)\n' + '\n'
    else '') +

  (if "1條件2=且用於術後輔助治療，pembrolizumab與olaparib僅能擇一支付"
    then '<主要規定三：藥品使用規則>\n' +
         '▲ 規則1-2：pembrolizumab與olaparib同時申請，僅能擇一支付\n' + '\n'
    else '') +

  (if not "2條件1-1=每位病人每個適應症限給付一種免疫檢查點抑制劑且不得互換"
    then '<主要規定三：藥品使用規則>\n' +
         '▲ 規則2-1：病人同時申請其他免疫檢查點抑制劑，每適應症限給付一種\n' + '\n'
    else '') +

  (if "2條件1-2=治療期間合併申報標靶藥物"
    then '<主要規定三：藥品使用規則>\n' +
         '▲ 規則2-2：治療期間合併申報標靶藥物(L01FD/L01EH/L01EF/L01EG02/L01XK/L01FX17)\n' + '\n'
    else '')


//============================================
// 列出「不符合」項目判斷式 - 必要資料未填寫
//============================================

define function "不符合項目_必要資料未填寫"():
  // 主要規定一：初次使用條件 - 必要資料未填寫
  (if Reusable."初次申請" and (
    not "一規則2=術前前導性治療併用Carboplatin和Paclitaxel且至多4個療程" or
    not "一規則3" or
    not "一規則4"
  )
    then '<主要規定一：初次使用條件>\n' +
         (if not "一規則2=術前前導性治療併用Carboplatin和Paclitaxel且至多4個療程"
           then '▲ 規則2：未提供carboplatin及paclitaxel併用前導性治療紀錄，或療程超過84天\n' else '') +
         (if not "3條件1=病人身體狀況良好(ECOG≦1)"
           then '▲ 規則3-1：未提供ECOG評估，或ECOG>1\n' else '') +
         (if not "3條件2=NYHA(the New York Heart Association) Functional Class I或II"
           then '▲ 規則3-2：未提供NYHA評估，或心功能不符(非Class I/II)\n' else '') +
         (if not "3條件3=GOT<60U/L及GPT<60U/L"
           then '▲ 規則3-3：未提供GOT/GPT數值，或GOT/GPT≥60U/L\n' else '') +
         (if not "3條件4=T-bilirubin<1.5mg/dL"
           then '▲ 規則3-4：未提供T-bilirubin數值，或T-bilirubin≥1.5mg/dL\n' else '') +
         (if not "3條件5=Creatinine<1.5mg/dL"
           then '▲ 規則3-5：未提供Creatinine數值，或Creatinine≥1.5mg/dL\n' else '') +
         (if not "3條件6=eGFR>60mL/min/1.73m2"
           then '▲ 規則3-6：未提供eGFR數值，或eGFR≤60mL/min/1.73m2\n' else '') +
         (if not "4條件1=病人12週內之疾病影像檢查及報告"
           then '▲ 條件4-1：未提供12週內之疾病影像報告\n' else '') +
         (if not "4條件3=使用免疫檢查點抑制劑之治療計畫"
           then '▲ 條件4-3：未附免疫檢查點抑制劑治療計畫\n' else '') +
         (if not "4條件4=使用於早期三陰性乳癌用藥時，初次申請時需檢附ER、PR及HER2為陰性之檢測報告"
           then '▲ 條件4-4：未提供ER、PR及HER2陰性之檢測報告\n' else '') +
         '\n'
    else '') +

  // 主要規定二：續用條件 - 必要資料未填寫
  (if Reusable."續用申請" and (
    not "二規則1=接續限pembrolizumab每3週1次與cyclophosphamide和doxorubicin或epirubicin併用至多4個療程，做為初診斷病人前導性治療用藥" or
    not "二規則2" or
    not "二規則4"
  )
    then '<主要規定二：續用條件>\n' +
         (if not "二規則1=接續限pembrolizumab每3週1次與cyclophosphamide和doxorubicin或epirubicin併用至多4個療程，做為初診斷病人前導性治療用藥"
           then '▲ 規則1：未提供cyclophosphamide及doxorubicin/epirubicin前導性治療紀錄，或療程超過84天\n' else '') +
         (if not "2條件1=手術後未達pCR者"
           then '▲ 規則2-1：未提供手術後pCR評估報告，或未記載未達pCR\n' else '') +
         (if not "2條件2=單用pembrolizumab每3週1次，做為輔助治療用藥，且至多使用9個療程"
           then '▲ 規則2-2：未提供pembrolizumab單用輔助治療紀錄，或療程超過189天\n' else '') +
         (if not "3條件2=6個月內影像報告"
           then '▲ 規則4：未提供6個月內影像報告\n' else '') +
         '\n'
    else '') +

  // 主要規定三：每次申請期間超限
  (if not "每次申請以12週為限"
    then '<主要規定三：藥品使用規則>\n' +
         '▲ 規則4：本次申請期間超過12週(84天)上限\n' + '\n'
    else '')


//============================================
// 審核結果
//============================================

define "乳癌Pembrolizumab申請結果_布林":
  case
    when Reusable."初次申請" then (
      "主要規定一" and
      "主要規定三"
    )
    when Reusable."續用申請" then (
      "主要規定二" and
      "主要規定三"
    )
    else false
  end

define "乳癌Pembrolizumab申請之CQL檢核結果":
  case
    when Reusable."申請類型未知" then '無法判斷申請類型，請確認續用註記'
    when "乳癌Pembrolizumab申請結果_布林" then '符合給付規定'
    else '不符合給付規定'
  end


//============================================
// 報告總結
//============================================

define "報告總結":
  '\n=== 早期三陰性乳癌之Pembrolizumab申請審核報告 ===\n' +
  '\n【申請類型】' + Reusable."申請類型" + '\n' +
  '\n【●符合項目】\n' +
  (if "符合項目"() = '' then '無\n' else "符合項目"()) +
  '\n【▲不符合項目 - 代碼或條件不符】\n' +
  (if "不符合項目_代碼或條件不符"() = '' then '無\n' else "不符合項目_代碼或條件不符"()) +
  '\n【▲不符合項目 - 必要資料未填寫】\n' +
  (if "不符合項目_必要資料未填寫"() = '' then '無\n' else "不符合項目_必要資料未填寫"()) +
  '\n【申請結果】\n' +
  "乳癌Pembrolizumab申請之CQL檢核結果" +
  '\n=================================================\n'
