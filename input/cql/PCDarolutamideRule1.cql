//攝護腺癌_Darolutamide給付規定-與docetaxel併用於治療高風險轉移性的去勢敏感性前列腺癌(mCSPC)
library PCDarolutamideRule1 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

include PCCodeConcept version '1.0.0' called CodeConcept

include PCReusable version '1.0.0' called Reusable

context Patient

//============================================
// 申請紀錄
//============================================

define "本次申請紀錄":
  Reusable."LatestMedicationPlan"(CodeConcept."L02BB06")

define "本次申請起始日期":
  FHIRHelpers.ToDateTime(("本次申請紀錄".dosageInstruction[0].timing.repeat.bounds as Period).start)

define "本次申請終止日期":
  FHIRHelpers.ToDateTime(("本次申請紀錄".dosageInstruction[0].timing.repeat.bounds as Period).end)

define "ICD-C61":
Reusable."主要疾病之ICD-10使用C61"

define "3個月內有影像檢查報告":
  Reusable."HasRecentImageReport"("本次申請起始日期", 90)

define "3個月內有檢查報告":
  Reusable."HasRecentMolecularReport"("本次申請起始日期", 90)

define "M≠0":
  Reusable."癌症分期分數或結果為M≠0"

//============================================
// 主要規定一：初次使用條件
//============================================

/*規則1*/
//條件1-1
define "docetaxel與申請藥品併用":
  "本次申請起始日期" is not null
  and exists (
    [MedicationRequest] MR
      where Reusable."HasMedicationCode"(MR, CodeConcept."L01CD02")
        and Reusable."HasValidTiming"(MR)
        and Reusable."GetStartTime"(MR) = "本次申請起始日期"
  )

define "1規則1-1":
"docetaxel與申請藥品併用"
and Reusable."續用註記為1"
and Reusable."醫令類別為1"

//條件1-2
define "1規則1-2-2":
  exists (
    [Observation] O
      where exists (
        O.code.coding Cdg
          where Cdg.code = '385377005'
            and Cdg in CodeConcept.SNOMED
      )
        and (
          (O.value is FHIR.integer and (O.value as FHIR.integer).value >= 8)
          or (O.value is FHIR.Quantity and (O.value as FHIR.Quantity).value >= 8)
          or (
            O.value is FHIR.string
            and (
              (ToDecimal(ReplaceMatches((O.value as FHIR.string).value, ',', '')) is not null
                and ToDecimal(ReplaceMatches((O.value as FHIR.string).value, ',', '')) >= 8)
              or Matches((O.value as FHIR.string).value, '(?i).*(>=|≧)\s*[89]\d*(?!\d).*')
            )
          )
        )
  )

define "1規則1-2-3":
  exists (
    [DiagnosticReport] Report
      where exists (
        Report.code.coding Cdg
          where (
            Cdg in CodeConcept.ICD10PCS2023Image
            or Cdg in CodeConcept.ICD10PCS2014Image
          )
          and Cdg.code in CodeConcept."imgItem_26029B代碼"
      )
      and Reusable."IsReportWithinDaysBefore"(Report, "本次申請起始日期", 90)
  )

define "1規則1-2-4":
  exists (
    [DiagnosticReport] Report
      where exists (
        Report.code.coding Cdg
          where (
            Cdg in CodeConcept.ICD10PCS2023Image
            or Cdg in CodeConcept.ICD10PCS2014Image
          )
          and Cdg.code in CodeConcept."DarolutamideVisceralMetastasisImageReportCode"
      )
      and Reusable."IsReportWithinDaysBefore"(Report, "本次申請起始日期", 90)
  )

define "1規則1-2":
("1規則1-2-2" and "1規則1-2-3")
or ("1規則1-2-2" and "1規則1-2-4")
or ("1規則1-2-3" and "1規則1-2-4")

//條件1-3
//系列PSA數據(3個月內)
define "PSA檢驗代碼":
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
            and Cdg.code in CodeConcept."PSACode"
        )
        and Reusable."IsObservationWithinDaysBefore"(OBs, "本次申請起始日期", 90)
  )

//系列睪固酮數據(3個月內)
define "睪固酮檢驗代碼":
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
            and Cdg.code in CodeConcept.Radium223LabTestCode
        )
        and Reusable."IsObservationWithinDaysBefore"(OBs, "本次申請起始日期", 90)
  )

//系列PSA和睪固酮數據(3個月內)
define "檢驗代碼":
"PSA檢驗代碼" and "睪固酮檢驗代碼"


define "去勢用藥代碼":
  CodeConcept."L02AE" union CodeConcept."L02BX02"

define "有去勢用藥處方":
  exists (
    [MedicationRequest] MR
      where Reusable."HasMedicationCode"(MR, "去勢用藥代碼")
  )

define "手術去勢處置項目":
  "本次申請起始日期" is not null
  and exists (
    [Procedure] P
      where P.status = 'completed'
        and exists (
          P.code.coding Cdg
            where (
              Cdg in CodeConcept.ICD10PCS2023Image
              or Cdg in CodeConcept.ICD10PCS2014Image
            )
            and Cdg.code in CodeConcept."SurgicalCastrationOPCode"
        )
        and P.performed is FHIR.dateTime
        and (duration in days between FHIRHelpers.ToDateTime(P.performed as FHIR.dateTime) and "本次申請起始日期") <= 90
  )

define "1規則1-3":
"ICD-C61"
and (
    (not "3個月內有影像檢查報告" and not "3個月內有檢查報告")
    or ("3個月內有影像檢查報告" and "3個月內有檢查報告")
  )
and "M≠0"
and "檢驗代碼"
and "有去勢用藥處方"
and "手術去勢處置項目"

define "1規則1":
"1規則1-1" and "1規則1-2" and "1規則1-3"

define "主要規定一":
"本次申請紀錄" is not null
and "1規則1"

//============================================
// 主要規定二：續用條件
//============================================

/*規則1*/
//條件1

//本次申請起始日期(含)以前,符合套組代碼之PSA檢驗紀錄
define "PSA檢驗清單":
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
            and Cdg.code in CodeConcept."PSACode"
      )
      and OBs.value is FHIR.Quantity
      and OBs.effective is not null
      and Reusable."EffectiveDateTime"(OBs.effective) <= "本次申請起始日期"

//檢驗(查)結果:至少要有2筆PSA數值
define "PSA檢驗數值至少2筆":
  Count("PSA檢驗清單") >= 2

//去重後的PSA檢驗報告日期(僅取日期,不含時間)
define "PSA檢驗日期清單":
  distinct (
    "PSA檢驗清單" OBs
      return date from Reusable."EffectiveDateTime"(OBs.effective)
  )

//檢驗(查)報告日期:至少要有2個不同的檢驗日期
define "PSA檢驗報告日期至少2筆":
  Count("PSA檢驗日期清單") >= 2

//依日期由新到舊排序之PSA檢驗日期清單
define "PSA日期新到舊清單":
  ("PSA檢驗日期清單") D
    sort desc

//依日期由新到舊排序,取各日期之PSA數值(同一天有多筆時取最大值)
define "PSA依日期排序清單":
  ("PSA日期新到舊清單") D
    return Max(
      "PSA檢驗清單" OBs
        where date from Reusable."EffectiveDateTime"(OBs.effective) = D
        return (OBs.value as FHIR.Quantity).value
    )

//本次PSA(最新一筆檢驗日期之數值)
define "本次PSA":
  "PSA依日期排序清單"[0]

//前次PSA(次新一筆檢驗日期之數值)
define "前次PSA":
  "PSA依日期排序清單"[1]

//檢驗(查)結果:(本次PSA-前次PSA)/本次PSA >= 50% 才可續用
define "PSA數值下降達50%":
  "本次PSA" is not null
  and "前次PSA" is not null
  and "本次PSA" > 0
  and (("本次PSA" - "前次PSA") / "本次PSA") >= 0.5

define "2規則1":
"PSA檢驗數值至少2筆"
and "PSA檢驗報告日期至少2筆"
and "PSA數值下降達50%"
and Reusable."續用註記為2"
and Reusable."醫令類別為1"

/*規則2*/
//條件1
define "3個月內影像報告顯示無疾病進展":
  exists (
    [DiagnosticReport] Report
      where exists (
        Report.code.coding Cdg
          where (
            Cdg in CodeConcept.ICD10PCS2023Image
            or Cdg in CodeConcept.ICD10PCS2014Image
          )
            and Cdg.code in CodeConcept."Radium223NoVisceralMetastasisImageReportCode"
      )
        and Reusable."IsReportWithinDaysBefore"(Report, "本次申請起始日期", 90)
        and Report.conclusion is not null
        and Matches(Report.conclusion.value, '(?i).*(無.{0,10}疾病進展|疾病穩定|stable disease|no.{0,10}progression).*')
  )

//本次申請起始日期(含)以前,符合套組代碼之PSA最低數值(治療期間PSA最低點)
define "最低PSA":
  Min(
    "PSA檢驗清單" OBs
      return (OBs.value as FHIR.Quantity).value
  )

//檢驗(查)結果條件1:(本次PSA-最低PSA)/本次PSA >= 50%
define "PSA較最低值上升達50%":
  "本次PSA" is not null
  and "最低PSA" is not null
  and "本次PSA" > 0
  and (("本次PSA" - "最低PSA") / "本次PSA") >= 0.5

//檢驗(查)結果條件2:本次PSA >= 2 ng/mL
define "本次PSA達2ngmL以上":
  "本次PSA" is not null
  and "本次PSA" >= 2

define "2規則2":
"3個月內影像報告顯示無疾病進展"
and "PSA檢驗數值至少2筆"
and "PSA檢驗報告日期至少2筆"
and "PSA較最低值上升達50%"
and "本次PSA達2ngmL以上"
and Reusable."續用註記為2"
and Reusable."醫令類別為1"

define "主要規定二":
"本次申請紀錄" is not null
and ("2規則1" or "2規則2")

//============================================
// 主要規定三：藥品使用規則
//============================================

/*規則1*/
define "3規則1-1-總療程以24個月為上限":
"本次申請起始日期" is not null
and "本次申請終止日期" is not null
and ((duration in days between "本次申請起始日期" and "本次申請終止日期") / 28) <= 24
and Reusable."醫令類別為1"

// 取得本次併用之 docetaxel 處方（起始日期與申請起始日期相符者）
define "本次併用docetaxel處方":
  First(
    [MedicationRequest] MR
      where Reusable."HasMedicationCode"(MR, CodeConcept."L01CD02")
        and Reusable."HasValidTiming"(MR)
        and Reusable."GetStartTime"(MR) = "本次申請起始日期"
      sort by Reusable."GetStartTime"($this)
  )

// docetaxel 給藥期間換算週數（三週給藥1次，18週即6個療程）
define "docetaxel給藥週數":
  if "本次併用docetaxel處方" is not null then
    (duration in days between
      Reusable."GetStartTime"("本次併用docetaxel處方")
      and Reusable."GetEndTime"("本次併用docetaxel處方")) / 7
  else null

// 給藥期間未逾18週
define "docetaxel給藥期間未逾18週":
  "docetaxel給藥週數" is not null
  and "docetaxel給藥週數" <= 18

define "3規則1-1-與docetaxel併用":
"docetaxel給藥期間未逾18週"

/*規則2*/
define "3規則2-2":
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
        and (
          (OBs.value is FHIR.integer and (OBs.value as FHIR.integer).value <= 1)
          or (OBs.value is FHIR.Quantity and (OBs.value as FHIR.Quantity).value <= 1)
          or (
            OBs.value is FHIR.string
            and (
              (ToDecimal(ReplaceMatches((OBs.value as FHIR.string).value, ',', '')) is not null
                and ToDecimal(ReplaceMatches((OBs.value as FHIR.string).value, ',', '')) <= 1)
              or Matches((OBs.value as FHIR.string).value, '(?i).*(<=|≦)\s*1(?!\d).*')
            )
          )
        )
  )

/*規則3*/
define "3規則3-3":
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
              and Cdg.code in CodeConcept.ANC
        )
        and (
          (OBs.value is FHIR.integer and (OBs.value as FHIR.integer).value >= 1500)
          or (OBs.value is FHIR.Quantity and (OBs.value as FHIR.Quantity).value >= 1500)
          or (
            OBs.value is FHIR.string
            and (
              (ToDecimal(ReplaceMatches((OBs.value as FHIR.string).value, ',', '')) is not null
                and ToDecimal(ReplaceMatches((OBs.value as FHIR.string).value, ',', '')) >= 1500)
              or Matches((OBs.value as FHIR.string).value, '(?i).*(>=|≧)\s*1,?500.*')
            )
          )
        )
  )

/*規則4*/
define "3規則4-4":
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
              and Cdg.code in CodeConcept.PlateletCount
        )
        and (
          (OBs.value is FHIR.integer and (OBs.value as FHIR.integer).value >= 100000)
          or (OBs.value is FHIR.Quantity and (OBs.value as FHIR.Quantity).value >= 100000)
          or (
            OBs.value is FHIR.string
            and (
              (ToDecimal(ReplaceMatches((OBs.value as FHIR.string).value, ',', '')) is not null
                and ToDecimal(ReplaceMatches((OBs.value as FHIR.string).value, ',', '')) >= 100000)
              or Matches((OBs.value as FHIR.string).value, '(?i).*(>=|≧)\s*100,?000.*')
            )
          )
        )
  )

/*規則5*/
//本次申請起始日期(含)以前,符合套組代碼之GPT(ALT)檢驗紀錄
define "GPT檢驗清單":
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
            and Cdg.code in CodeConcept."GPT"
      )
      and OBs.value is FHIR.Quantity
      and OBs.effective is not null

define "GPT資料存在":
  exists ("GPT檢驗清單")

//去重後的GPT檢驗日期(僅取日期)
define "GPT檢驗日期清單":
  distinct (
    "GPT檢驗清單" OBs
      return date from Reusable."EffectiveDateTime"(OBs.effective)
  )

//依日期由新到舊排序之GPT檢驗日期清單
define "GPT日期新到舊清單":
  ("GPT檢驗日期清單") D
    sort desc

//依日期由新到舊排序,取各日期之GPT數值(同一天多筆取最大值)
define "GPT依日期排序清單":
  ("GPT日期新到舊清單") D
    return Max(
      "GPT檢驗清單" OBs
        where date from Reusable."EffectiveDateTime"(OBs.effective) = D
        return (OBs.value as FHIR.Quantity).value
    )

//本次GPT(最新一筆檢驗日期之數值)
define "本次GPT":
  "GPT依日期排序清單"[0]

//檢驗(查)結果:GPT ≦ 80 U/L(即GPT正常值上限40 U/L之2倍以下)
define "3規則5-5":
  "本次GPT" is not null
  and "本次GPT" <= 80

/*規則6*/
define "3規則6-6":
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
              and Cdg.code in CodeConcept."CreatinineCode"
        )
        and (
          //檢驗(查)結果數值本身 <= 1.2 mg/dL
          (OBs.value is FHIR.Quantity and (OBs.value as FHIR.Quantity).value <= 1.2)
          or (
            OBs.value is FHIR.string
            and (
              (ToDecimal(ReplaceMatches((OBs.value as FHIR.string).value, ',', '')) is not null
                and ToDecimal(ReplaceMatches((OBs.value as FHIR.string).value, ',', '')) <= 1.2)
              or Matches((OBs.value as FHIR.string).value, '(?i).*(<=|≦)\s*1\.?2(?!\d).*')
            )
          )
          //定性結果時,退回檢查該筆檢驗自帶的參考範圍上限 <= 1.2 mg/dL
          or exists (
            OBs.referenceRange RR
              where RR.high is not null
                and (RR.high as FHIR.Quantity).value <= 1.2
          )
        )
  )

/*規則7*/
//檢驗(查)結果:eGFR ≧ 30 mL/min/1.73m2
define "3規則7-7":
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
        and (
          //檢驗(查)結果數值本身 >= 30 mL/min/1.73m2
          (OBs.value is FHIR.integer and (OBs.value as FHIR.integer).value >= 30)
          or (OBs.value is FHIR.Quantity and (OBs.value as FHIR.Quantity).value >= 30)
          or (
            OBs.value is FHIR.string
            and (
              (ToDecimal(ReplaceMatches((OBs.value as FHIR.string).value, ',', '')) is not null
                and ToDecimal(ReplaceMatches((OBs.value as FHIR.string).value, ',', '')) >= 30)
              or Matches((OBs.value as FHIR.string).value, '(?i).*(>=|≧)\s*30(?!\d).*')
            )
          )
          //定性結果時,退回檢查該筆檢驗自帶的參考範圍下限 >= 30 mL/min/1.73m2
          or exists (
            OBs.referenceRange RR
              where RR.low is not null
                and (RR.low as FHIR.Quantity).value >= 30
          )
        )
  )

/*規則8*/
define "有Abiraterone處方":
  exists (
    [MedicationRequest] MR
      where Reusable."HasMedicationCode"(MR, CodeConcept."L02BX03")
  )

define "有Apalutamide處方":
  exists (
    [MedicationRequest] MR
      where Reusable."HasMedicationCode"(MR, CodeConcept."L02BB05")
  )

define "有Enzalutamide處方":
  exists (
    [MedicationRequest] MR
      where Reusable."HasMedicationCode"(MR, CodeConcept."L02BB04")
  )

//olaparib 與 abiraterone 併用：兩藥處方期間需重疊
define "Olaparib與Abiraterone併用":
  exists (
    [MedicationRequest] OlaMR
      where Reusable."HasMedicationCode"(OlaMR, CodeConcept."L01XK01")
        and Reusable."HasValidTiming"(OlaMR)
        and exists (
          [MedicationRequest] AbiMR
            where AbiMR.id != OlaMR.id
              and Reusable."HasMedicationCode"(AbiMR, CodeConcept."L02BX03")
              and Reusable."HasValidTiming"(AbiMR)
              and Reusable."GetStartTime"(OlaMR) <= Reusable."GetEndTime"(AbiMR)
              and Reusable."GetEndTime"(OlaMR) >= Reusable."GetStartTime"(AbiMR)
        )
  )

define "3規則8-1":
Reusable."續用註記為1"
and Reusable."醫令類別為1"
and not ( "有Abiraterone處方"
or "有Apalutamide處方"
or "有Enzalutamide處方"
or "Olaparib與Abiraterone併用" )

define "主要規定三":
"本次申請紀錄" is not null
and "3規則1-1-總療程以24個月為上限"
and "3規則1-1-與docetaxel併用"
and "3規則2-2"
and "3規則3-3"
and "3規則4-4"
and "3規則5-5"
and "3規則6-6"
and "3規則7-7"
and "3規則8-1"

//============================================
// 檢核結果用：必要資料存在判斷
//============================================

define "Darolutamide申請資料存在":
  Reusable."HasMedicationPlanRecord"(CodeConcept."L02BB06")

define "醫令類別資料存在":
  exists (
    [Claim] C
      where exists (
        C.item I
          where exists (
            I.productOrService.coding PSC
              where PSC in CodeConcept.NHIOrderType
          )
      )
  )

define "療程期間資料存在":
  Reusable."HasMedicationPlanTiming"(CodeConcept."L02BB06")

define "攝護腺癌ICD診斷資料存在":
  Reusable."主要疾病ICD診斷資料存在"

define "docetaxel併用處方資料存在":
  exists (
    [MedicationRequest] MR
      where Reusable."HasMedicationCode"(MR, CodeConcept."L01CD02")
  )

define "Gleason score資料存在":
  exists (
    [Observation] O
      where exists (
        O.code.coding Cdg
          where Cdg.code = '385377005'
            and Cdg in CodeConcept.SNOMED
      )
  )

define "26029B影像報告資料存在":
  exists (
    [DiagnosticReport] Report
      where exists (
        Report.code.coding Cdg
          where (
            Cdg in CodeConcept.ICD10PCS2023Image
            or Cdg in CodeConcept.ICD10PCS2014Image
          )
          and Cdg.code in CodeConcept."imgItem_26029B代碼"
      )
  )

define "內臟轉移影像報告資料存在":
  exists (
    [DiagnosticReport] Report
      where exists (
        Report.code.coding Cdg
          where (
            Cdg in CodeConcept.ICD10PCS2023Image
            or Cdg in CodeConcept.ICD10PCS2014Image
          )
          and Cdg.code in CodeConcept."DarolutamideVisceralMetastasisImageReportCode"
      )
  )

define "影像報告資料存在":
  exists (
    [DiagnosticReport] Report
      where Reusable."IsImageReport"(Report)
  )

define "分子檢查報告資料存在":
  exists (
    [DiagnosticReport] Report
      where Reusable."IsMolecularReport"(Report)
  )

define "PSA檢驗資料存在":
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
            and Cdg.code in CodeConcept."PSACode"
        )
  )

define "睪固酮檢驗資料存在":
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
            and Cdg.code in CodeConcept.Radium223LabTestCode
        )
  )

define "手術去勢處置資料存在":
  exists (
    [Procedure] P
      where P.status = 'completed'
        and exists (
          P.code.coding Cdg
            where (
              Cdg in CodeConcept.ICD10PCS2023Image
              or Cdg in CodeConcept.ICD10PCS2014Image
            )
            and Cdg.code in CodeConcept."SurgicalCastrationOPCode"
        )
  )

define "ECOG資料存在":
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
  )

define "ANC資料存在":
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
              and Cdg.code in CodeConcept.ANC
        )
  )

define "PlateletCount資料存在":
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
              and Cdg.code in CodeConcept.PlateletCount
        )
  )

define "Creatinine資料存在":
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
              and Cdg.code in CodeConcept."CreatinineCode"
        )
  )

define "eGFR資料存在":
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
  )

define "必要資料皆存在":
  not (
    (
      Reusable."初次申請" and (
        not "Darolutamide申請資料存在"
        or not "醫令類別資料存在"
        or not "攝護腺癌ICD診斷資料存在"
        or not "docetaxel併用處方資料存在"
        or (not "Gleason score資料存在" and not "26029B影像報告資料存在" and not "內臟轉移影像報告資料存在")
        or not "PSA檢驗資料存在"
        or not "睪固酮檢驗資料存在"
        or (not "有去勢用藥處方" and not "手術去勢處置資料存在")
      )
    )
    or (
      Reusable."續用申請" and (
        not "Darolutamide申請資料存在"
        or not "醫令類別資料存在"
        or not "PSA檢驗資料存在"
      )
    )
    or not "療程期間資料存在"
  )

//============================================
// 列出「符合」項目判斷式
//============================================

define function "符合項目"():
  // 主要規定一：初次使用條件
  (if Reusable."初次申請" and (
      "1規則1-1" or "1規則1-2" or "1規則1-3"
    )
    then '<主要規定一：初次使用條件>\n' +
         (if "1規則1-1" then '● 規則1-1：與docetaxel併用，且續用註記及醫令類別符合條件\n' else '') +
         (if "1規則1-2" then '● 規則1-2：Gleason score≧8、26029B影像報告、內臟轉移影像報告三項擇二符合\n' else '') +
         (if "1規則1-3" then '● 規則1-3：ICD-C61、影像/檢查報告、M≠0、PSA及睪固酮檢驗、去勢用藥處方或手術去勢處置符合條件\n' else '') +
         '\n'
    else '') +

  // 主要規定二：續用條件
  (if Reusable."續用申請" and (
      "2規則1" or "2規則2"
    )
    then '<主要規定二：續用條件>\n' +
         (if "2規則1" then '● 續用規則1：PSA數值較前次下降達50%以上，且申請註記與醫令類別符合條件\n' else '') +
         (if "2規則2" then '● 續用規則2：3個月內影像報告顯示無疾病進展，且PSA較最低值上升達50%以上或本次PSA≧2 ng/mL，申請註記與醫令類別符合條件\n' else '') +
         '\n'
    else '') +

  // 主要規定三：藥品使用規則
  (if ("3規則1-1-總療程以24個月為上限" or "3規則1-1-與docetaxel併用" or "3規則2-2" or "3規則3-3"
      or "3規則4-4" or "3規則5-5" or "3規則6-6" or "3規則7-7" or "3規則8-1"
    )
    then '<主要規定三：藥品使用規則>\n' +
         (if "3規則1-1-總療程以24個月為上限" then '● 規則1：總療程未逾24個月上限（參考資訊）\n' else '') +
         (if "3規則1-1-與docetaxel併用" then '● 規則1：與docetaxel併用之給藥期間未逾18週（參考資訊）\n' else '') +
         (if "3規則2-2" then '● 規則2：ECOG PS≦1（參考資訊）\n' else '') +
         (if "3規則3-3" then '● 規則3：ANC≧1500/mm3（參考資訊）\n' else '') +
         (if "3規則4-4" then '● 規則4：血小板≧100,000/mm3（參考資訊）\n' else '') +
         (if "3規則5-5" then '● 規則5：GPT(ALT)≦80 U/L（參考資訊）\n' else '') +
         (if "3規則6-6" then '● 規則6：肌酸酐≦1.2 mg/dL（參考資訊）\n' else '') +
         (if "3規則7-7" then '● 規則7：eGFR≧30 mL/min/1.73m2（參考資訊）\n' else '') +
         (if "3規則8-1" then '● 規則8：未併用Abiraterone、Apalutamide、Enzalutamide或Olaparib與Abiraterone併用（參考資訊）\n' else '') +
         '\n'
    else '')

//============================================
// 列出「不符合」項目判斷式 - 條件或代碼不符合
//============================================

define function "不符合項目_條件或代碼不符合"():
  // 主要規定一：初次使用條件 - 已提供資料但條件或代碼不符合
  (if Reusable."初次申請" and (
      ("docetaxel併用處方資料存在" and not "1規則1-1")
      or (("Gleason score資料存在" or "26029B影像報告資料存在" or "內臟轉移影像報告資料存在") and not "1規則1-2")
      or (("攝護腺癌ICD診斷資料存在" and "PSA檢驗資料存在" and "睪固酮檢驗資料存在") and not "1規則1-3")
    )
    then '<主要規定一：初次使用條件>\n' +
         (if "docetaxel併用處方資料存在" and not "1規則1-1" then '▲ 規則1-1：docetaxel併用處方期間、續用註記或醫令類別不符合條件\n' else '') +
         (if ("Gleason score資料存在" or "26029B影像報告資料存在" or "內臟轉移影像報告資料存在") and not "1規則1-2" then '▲ 規則1-2：Gleason score或影像報告不符合擇二條件\n' else '') +
         (if ("攝護腺癌ICD診斷資料存在" and "PSA檢驗資料存在" and "睪固酮檢驗資料存在") and not "1規則1-3" then '▲ 規則1-3：ICD代碼、影像/檢查報告、分期、PSA、睪固酮、去勢用藥處方或手術去勢處置不符合條件\n' else '') +
         '\n'
    else '') +

  // 主要規定二：續用條件 - 已提供資料但條件或代碼不符合
  (if Reusable."續用申請" and (
      ("PSA檢驗資料存在" and not "2規則1")
      or (("PSA檢驗資料存在" and "影像報告資料存在") and not "2規則2")
    )
    then '<主要規定二：續用條件>\n' +
         (if "PSA檢驗資料存在" and not "2規則1" then '▲ 續用規則1：PSA檢驗筆數、日期或下降幅度不符合續用規則1條件\n' else '') +
         (if ("PSA檢驗資料存在" and "影像報告資料存在") and not "2規則2" then '▲ 續用規則2：影像報告或PSA上升趨勢不符合續用規則2條件\n' else '') +
         '\n'
    else '') +

  // 主要規定三：藥品使用規則 - 已提供資料但條件或代碼不符合
  (if (("療程期間資料存在" and not "3規則1-1-總療程以24個月為上限")
      or ("docetaxel併用處方資料存在" and not "3規則1-1-與docetaxel併用")
      or ("ECOG資料存在" and not "3規則2-2")
      or ("ANC資料存在" and not "3規則3-3")
      or ("PlateletCount資料存在" and not "3規則4-4")
      or ("GPT資料存在" and not "3規則5-5")
      or ("Creatinine資料存在" and not "3規則6-6")
      or ("eGFR資料存在" and not "3規則7-7")
      or ("攝護腺癌ICD診斷資料存在" and not "3規則8-1")
    )
    then '<主要規定三：藥品使用規則>\n' +
         (if "療程期間資料存在" and not "3規則1-1-總療程以24個月為上限" then '▲ 規則1：總療程超過24個月上限（參考資訊）\n' else '') +
         (if "docetaxel併用處方資料存在" and not "3規則1-1-與docetaxel併用" then '▲ 規則1：與docetaxel併用之給藥期間超過18週（參考資訊）\n' else '') +
         (if "ECOG資料存在" and not "3規則2-2" then '▲ 規則2：ECOG評估結果不符合PS≦1（參考資訊）\n' else '') +
         (if "ANC資料存在" and not "3規則3-3" then '▲ 規則3：ANC未達1500/mm3（參考資訊）\n' else '') +
         (if "PlateletCount資料存在" and not "3規則4-4" then '▲ 規則4：血小板未達100,000/mm3（參考資訊）\n' else '') +
         (if "GPT資料存在" and not "3規則5-5" then '▲ 規則5：GPT(ALT)超過80 U/L（參考資訊）\n' else '') +
         (if "Creatinine資料存在" and not "3規則6-6" then '▲ 規則6：肌酸酐超過1.2 mg/dL（參考資訊）\n' else '') +
         (if "eGFR資料存在" and not "3規則7-7" then '▲ 規則7：eGFR未達30 mL/min/1.73m2（參考資訊）\n' else '') +
         (if "攝護腺癌ICD診斷資料存在" and not "3規則8-1" then '▲ 規則8：合併使用Abiraterone、Apalutamide、Enzalutamide，或Olaparib與Abiraterone併用（參考資訊）\n' else '') +
         '\n'
    else '')

//============================================
// 列出「不符合」項目判斷式 - 必要資料未填寫
//============================================

define function "不符合項目_必要資料未填寫"():
  // 申請類型無法判定
  (if Reusable."申請類型" = '無法判定申請類型'
    then '▲ 申請類型：未提供可判定初次使用或續用之申請註記\n\n'
    else '') +

  // 主要規定一：初次使用條件 - 必要資料未填寫
  (if Reusable."初次申請" and (
      not "Darolutamide申請資料存在"
      or not "醫令類別資料存在"
      or not "攝護腺癌ICD診斷資料存在"
      or not "docetaxel併用處方資料存在"
      or (not "Gleason score資料存在" and not "26029B影像報告資料存在" and not "內臟轉移影像報告資料存在")
      or not "PSA檢驗資料存在"
      or not "睪固酮檢驗資料存在"
      or (not "有去勢用藥處方" and not "手術去勢處置資料存在")
    )
    then '<主要規定一：初次使用條件>\n' +
         (if not "Darolutamide申請資料存在" then '▲ 申請醫令：未提供Darolutamide申請醫令資料\n' else '') +
         (if not "醫令類別資料存在" then '▲ 申請醫令：未提供醫令類別資料\n' else '') +
         (if not "攝護腺癌ICD診斷資料存在" then '▲ 規則1-3：未提供主要疾病ICD診斷資料\n' else '') +
         (if not "docetaxel併用處方資料存在" then '▲ 規則1-1：未提供docetaxel併用處方資料\n' else '') +
         (if not "Gleason score資料存在" and not "26029B影像報告資料存在" and not "內臟轉移影像報告資料存在" then '▲ 規則1-2：未提供Gleason score或影像報告資料\n' else '') +
         (if not "PSA檢驗資料存在" then '▲ 規則1-3：未提供PSA檢驗資料\n' else '') +
         (if not "睪固酮檢驗資料存在" then '▲ 規則1-3：未提供睪固酮檢驗資料\n' else '') +
         (if not "有去勢用藥處方" and not "手術去勢處置資料存在" then '▲ 規則1-3：未提供去勢用藥處方或手術去勢處置資料\n' else '') +
         '\n'
    else '') +

  // 主要規定二：續用條件 - 必要資料未填寫
  (if Reusable."續用申請" and (
      not "Darolutamide申請資料存在"
      or not "醫令類別資料存在"
      or not "PSA檢驗資料存在"
    )
    then '<主要規定二：續用條件>\n' +
         (if not "Darolutamide申請資料存在" then '▲ 申請醫令：未提供Darolutamide申請醫令資料\n' else '') +
         (if not "醫令類別資料存在" then '▲ 申請醫令：未提供醫令類別資料\n' else '') +
         (if not "PSA檢驗資料存在" then '▲ 續用規則1/2：未提供PSA檢驗資料\n' else '') +
         '\n'
    else '') +

  // 主要規定三：藥品使用規則 - 必要資料未填寫
  (if not "療程期間資料存在"
    then '<主要規定三：藥品使用規則>\n' +
         '▲ 規則1：未提供療程起迄日期資料（參考資訊）\n' +
         '\n'
    else '')

//============================================
// 審核結果
//============================================

define "攝護腺癌Darolutamide申請結果_布林":
  case
    when Reusable."初次申請" then "主要規定一"
    when Reusable."續用申請" then "主要規定二"
    else false
  end

define "攝護腺癌Darolutamide申請結果":
  if Reusable."初次申請" and "攝護腺癌Darolutamide申請結果_布林"
  then '✓通過：初次使用－攝護腺癌 Darolutamide 用藥申請'
  else if Reusable."續用申請" and "攝護腺癌Darolutamide申請結果_布林"
  then '✓通過：續用－攝護腺癌 Darolutamide 用藥申請'
  else if Reusable."初次申請"
  then '✖不通過：初次使用－攝護腺癌 Darolutamide 用藥申請'
  else if Reusable."續用申請"
  then '✖不通過：續用－攝護腺癌 Darolutamide 用藥申請'
  else '✖不通過：無法判定申請類型－攝護腺癌 Darolutamide 用藥申請'

//============================================
// 審核報告總結
//============================================

define "報告總結":
  '\n=== 攝護腺癌之Darolutamide（與docetaxel併用治療mCSPC）申請審核報告 ===\n' +
  '\n※ 備註：標示為「參考資訊」之檢核項目，係供審核參酌使用，不作為最終【申請結果】判定之依據。\n' +
  '\n【申請類型】' + Reusable."申請類型" + '\n' +
  '\n【●符合項目】\n' +
  (if "符合項目"() = '' then '無\n' else "符合項目"()) +
  '\n【▲不符合項目 - 必要資料未填寫】\n' +
  (if "不符合項目_必要資料未填寫"() = '' then '無\n' else "不符合項目_必要資料未填寫"()) +
  '\n【▲不符合項目 - 條件或代碼不符合】\n' +
  (if "不符合項目_條件或代碼不符合"() = '' then '無\n' else "不符合項目_條件或代碼不符合"()) +
  '\n【申請結果】\n' +
  "攝護腺癌Darolutamide申請結果" +
  '\n===============================================\n'
