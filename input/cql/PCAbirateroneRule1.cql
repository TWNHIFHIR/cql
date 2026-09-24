//攝護腺癌_Abiraterone給付規定
library PCAbirateroneRule1 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

include PCCodeConcept version '1.0.0' called CodeConcept

include PCReusable version '1.0.0' called Reusable

context Patient

//============================================
// 申請紀錄
//============================================

define "本次申請紀錄":
  Reusable."LatestMedicationPlan"(CodeConcept."L02BX03")

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
//條件1
define "簡要病摘-去勢敏感":
exists (
    [Claim] C
      where exists (
        C.diagnosis D
          where exists (
            D.type.text T
              where Matches(T.value, '(?i).*去勢敏感.*')
          )
      )
  )

define "PSAExtended檢驗代碼":
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
            and Cdg.code in CodeConcept."PSALabTestCodeExtended"
        )
    and Reusable."IsObservationWithinDaysBefore"(OBs, "本次申請起始日期", 90)
  )

define "mCRPC藥物代碼":
  CodeConcept."L02AE" union CodeConcept."L02BX02"

define "處方時間":
  exists (
    [MedicationRequest] MR
      where Reusable."HasMedicationCode"(MR, "mCRPC藥物代碼")
        and Reusable."HasValidTiming"(MR)
        and Reusable."GetStartTime"(MR) < "本次申請終止日期"
        and Reusable."GetEndTime"(MR) < "本次申請終止日期"
  )

define "手術項目":
  Reusable."HasRecentSurgicalCastrationProcedure"("本次申請起始日期", 90)

define "1規則1-1":
"ICD-C61"
and "簡要病摘-去勢敏感"
and (
    (not "3個月內有影像檢查報告" and not "3個月內有檢查報告")
    or ("3個月內有影像檢查報告" and "3個月內有檢查報告")
  )
and "M≠0"
and "PSAExtended檢驗代碼"
and "處方時間"
and "手術項目"
and Reusable."用藥線別=1"
and Reusable."續用註記為1"
and Reusable."醫令類別為1"

//條件2
define "1規則1-2":
"本次申請起始日期" is not null
  and Patient.birthDate is not null
  and AgeInYearsAt(date from "本次申請起始日期") >= 18

//條件3
define "1規則1-3":
Patient.gender.value = 'male'

//條件4
define "處方時間-區間":
  exists (
    [MedicationRequest] MR
      where Reusable."HasMedicationCode"(MR, "mCRPC藥物代碼")
        and Reusable."HasValidTiming"(MR)
        and Reusable."GetStartTime"(MR) <= "本次申請起始日期"
        and Reusable."GetEndTime"(MR) >= "本次申請終止日期"
  )

define "手術項目-併用":
  Reusable."HasSurgicalCastrationProcedureWithinPeriod"("本次申請起始日期", "本次申請終止日期")

define "1規則1-4":
"處方時間-區間" and "手術項目-併用"

//條件5
define "1規則1-5":
  exists (
    [MedicationRequest] MR
      where Reusable."HasMedicationCode"(MR, CodeConcept."皮質類固醇藥物代碼")
        and Reusable."HasValidTiming"(MR)
        and Reusable."GetStartTime"(MR) <= "本次申請起始日期"
        and Reusable."GetEndTime"(MR) >= "本次申請終止日期"
  )

//條件6
define "1規則1-6":
  Reusable."HasRecentECOGAtMost"(1, "本次申請起始日期", 90)

//條件7
define "1規則1-7-2":
  Reusable."HasGleasonScoreAtLeast8"

define "1規則1-7-3":
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

define "1規則1-7-4":
  exists (
    [DiagnosticReport] Report
      where exists (
        Report.code.coding Cdg
          where (
            Cdg in CodeConcept.ICD10PCS2023Image
            or Cdg in CodeConcept.ICD10PCS2014Image
          )
          and Cdg.code in CodeConcept."VisceralMetastasisImageReportCode"
      )
      and Reusable."IsReportWithinDaysBefore"(Report, "本次申請起始日期", 90)
  )

define "1規則1-7":
("1規則1-7-2" and "1規則1-7-3")
or ("1規則1-7-2" and "1規則1-7-4")
or ("1規則1-7-3" and "1規則1-7-4")

//條件8
define "照護計畫文件資料存在":
  Reusable."HasCarePlanDocument"
  and (
    Reusable."HasMedicationRecord"("mCRPC藥物代碼")
    or "手術項目"
  )

define "1規則1-8":
"3個月內有檢查報告"
and "PSAExtended檢驗代碼"
and "處方時間"
and "手術項目"
and "照護計畫文件資料存在"

define "1規則1":
"1規則1-1" and "1規則1-2" and "1規則1-3" and "1規則1-4"
and "1規則1-5" and "1規則1-6" and "1規則1-7" and "1規則1-8"

/*規則2*/
//條件1
define "簡要病摘-去勢抗性":
exists (
    [Claim] C
      where exists (
        C.diagnosis D
          where exists (
            D.type.text T
              where Matches(T.value, '(?i).*去勢抗性.*')
          )
      )
  )

define "1規則2-1":
"ICD-C61"
and "簡要病摘-去勢抗性"
and (
    (not "3個月內有影像檢查報告" and not "3個月內有檢查報告")
    or ("3個月內有影像檢查報告" and "3個月內有檢查報告")
  )
and "M≠0"
and "PSAExtended檢驗代碼"
and "處方時間"
and "手術項目"
and "照護計畫文件資料存在"
and Reusable."續用註記為1"
and Reusable."醫令類別為1"

//條件2
define "1規則2-2":
"1規則1-5"

//條件3
define "1規則2-3":
"處方時間"

//條件4
define "1規則2-4":
"1規則1-6"

//條件5
define "簡要病摘-未接受過化療":
exists (
    [Claim] C
      where exists (
        C.diagnosis D
          where exists (
            D.type.text T
              where Matches(T.value, '(?i).*未接受過化療.*')
          )
      )
  )

define "化療藥物代碼":
  CodeConcept."L01CD" union CodeConcept."L01AA01" union CodeConcept."L01DB07"

define "1規則2-5":
"簡要病摘-未接受過化療" 
and not Reusable."HasMedicationRecord"("化療藥物代碼")

//條件6
define "1規則2-6-1":
exists (
    [Claim] C
      where exists (
        C.diagnosis D
          where exists (
            D.type.text T
              where Matches(T.value, '(?i).*先前接受雄性素去除療法時，在小於12個月的時間內演化成去勢抗性前列腺癌(CRPC).*')
          )
      )
  )

define "1規則2-6-2":
"1規則1-7-2"

define "簡要病摘-使用過化學治療":
exists (
    [Claim] C
      where exists (
        C.diagnosis D
          where exists (
            D.type.text T
              where Matches(T.value, '(?i).*使用過化學治療.*')
          )
      )
  )

define "處方時間-化療藥物代碼":
  exists (
    [MedicationRequest] MR
      where Reusable."HasMedicationCode"(MR, "化療藥物代碼")
        and Reusable."HasValidTiming"(MR)
        and Reusable."GetStartTime"(MR) < "本次申請終止日期"
        and Reusable."GetEndTime"(MR) < "本次申請終止日期"
  )

define "1規則2-6-3":
"簡要病摘-使用過化學治療" and "處方時間-化療藥物代碼"

define "1規則2-6":
"1規則2-6-1" and "1規則2-6-2" and "1規則2-6-3"

//條件7
define "N02M01藥品代碼":
  CodeConcept."N02" union CodeConcept."M01"

define "1規則2-7":
  exists (
    [MedicationRequest] MR
      where exists (
        MR.medication.coding Cdg
          where Cdg in CodeConcept.NHIMedication
            and Cdg.code in "N02M01藥品代碼"
      )
        and exists (
          MR.dosageInstruction DI
            where exists (
              DI.timing.code.coding C
                where C.code = 'PRN'
            )
        )
  )

//條件8
define "1規則2-8":
"3個月內有影像檢查報告"

//條件9
define "1規則2-9":
"3個月內有檢查報告"
and "PSAExtended檢驗代碼"
and "處方時間"
and "手術項目"
and "照護計畫文件資料存在"

define "1規則2":
"1規則2-1" and "1規則2-2" and "1規則2-3" and "1規則2-4" and "1規則2-5" 
and "1規則2-6" and "1規則2-7" and "1規則2-8" and "1規則2-9"

/*規則3*/
//條件1
define "1規則3-1":
"ICD-C61"
and "簡要病摘-去勢抗性"
and (
    (not "3個月內有影像檢查報告" and not "3個月內有檢查報告")
    or ("3個月內有影像檢查報告" and "3個月內有檢查報告")
  )
and "M≠0"
and "PSAExtended檢驗代碼"
and "處方時間"
and "手術項目"
and "照護計畫文件資料存在"
and Reusable."續用註記為1"
and Reusable."醫令類別為1"

//條件2
define "1規則3-2":
"1規則1-5"

//條件3
define "1規則3-3":
  Reusable."HasRecentECOGAtMost"(2, "本次申請起始日期", 90)

//條件4
define "1規則3-4":
  exists (
    [MedicationRequest] MR
      where Reusable."HasMedicationCode"(MR, CodeConcept."L01CD02")
        and Reusable."HasValidTiming"(MR)
        and (days between Reusable."GetStartTime"(MR) and Reusable."GetEndTime"(MR)) >= 42
  )

//條件5
define "1規則3-5":
"3個月內有檢查報告"
and "PSAExtended檢驗代碼"
and "處方時間"
and "手術項目"
and "照護計畫文件資料存在"

define "1規則3":
"1規則3-1" and "1規則3-2" and "1規則3-3"
and "1規則3-4" and "1規則3-5"

/*規則4*/
//條件1
//事前審查藥物預定處方起始日期(useSdate)
define "useSdate":
  Reusable."GetStartTime"("本次申請紀錄")

//事前審查藥物預定處方終止日期(useEdate)
define "useEdate":
  Reusable."GetEndTime"("本次申請紀錄")

define "L01XK01處方期間涵蓋申請區間":
  exists (
    [MedicationRequest] MR
      where Reusable."HasMedicationCode"(MR, CodeConcept."L01XK01")
        and Reusable."HasValidTiming"(MR)
        and Reusable."GetStartTime"(MR) <= "useSdate"
        and Reusable."GetEndTime"(MR) >= "useEdate"
  )

define "1規則4-1":
"ICD-C61"
and "L01XK01處方期間涵蓋申請區間"
and Reusable."續用註記為1"
and Reusable."醫令類別為1"

//條件2
define "1規則4-2":
"L01XK01處方期間涵蓋申請區間"

//條件3
define "1規則4-3":
"1規則1-5"

//條件4
define "1規則4-4":
  exists (
    [Observation] RasO
    where RasO.status = 'final'
      and exists (
        RasO.code.coding ObsCodeCoding
        where ObsCodeCoding.code = '69548-6'
          and ObsCodeCoding in CodeConcept.LOINC
      )
      and exists (
        RasO.component ComponentRecord
        where exists (
          ComponentRecord.code.coding ComponentCodeCoding
          where ComponentCodeCoding.code in CodeConcept.BRCA1_2GeneMutationTestCode
        )
        and ComponentRecord.value is not null
        and ComponentRecord.value is FHIR.string
        and Matches((ComponentRecord.value as FHIR.string).value, '(?i).*(Positive|Pathogenic|Likely Pathogenic|mutation|deletion).*')
      )
  )

//條件5
define "1規則4-5":
"1規則1-2"

define "1規則4":
"1規則4-1" and "1規則4-2" and "1規則4-3" and "1規則4-4" and "1規則4-5"

define "主要規定一":
"本次申請紀錄" is not null
and ("1規則1" or "1規則2" or "1規則3" or "1規則4")

//============================================
// 主要規定二：續用條件
//============================================

/*規則1*/
//條件1
define "2規則1-1":
"ICD-C61"
and Reusable."續用註記為2"
and Reusable."醫令類別為1"

//條件2
define "2規則1-2-1":
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
            and Cdg.code in CodeConcept."PSALabTestCodeBasic"
        )
    and Reusable."IsObservationWithinDaysBefore"(OBs, "本次申請起始日期", 90)
  )

define "2規則1-2-2-1":
"2規則1-2-1"

define "2規則1-2-2-2":
"2規則1-2-1"

define "2規則1-2-2-3":
"2規則1-2-1"

define "2規則1-2-2":
"2規則1-2-2-1" and "2規則1-2-2-2" or "2規則1-2-2-3"

define "2規則1-2":
"2規則1-2-1" or "2規則1-2-2"

define "2規則1":
"2規則1-1" and "2規則1-2"

define "主要規定二":
"本次申請紀錄" is not null
and "2規則1-1" and "2規則1-2"

//============================================
// 主要規定三：藥品使用規則
//============================================

/*規則1*/
//條件1
define "3規則1-1":
Reusable."醫令類別為1"

//條件2
define "3規則1-2":
Reusable."醫令類別為1"
and (duration in months between "本次申請起始日期" and "本次申請終止日期") <= 3

define "3規則1":
"3規則1-1" and "3規則1-2"

/*規則2*/
//條件1
define "3規則2-1":
"1規則1-2"
and "1規則1-3"
and "ICD-C61"
and "簡要病摘-去勢敏感"
and (
    (not "3個月內有影像檢查報告" and not "3個月內有檢查報告")
    or ("3個月內有影像檢查報告" and "3個月內有檢查報告")
  )
and "M≠0"
and "PSAExtended檢驗代碼"
and "處方時間"
and "手術項目"

//條件2
define "3規則2-2":
  "useSdate" is not null
  and "useEdate" is not null
  and Reusable."HasMedicationTotalDurationWithin"(CodeConcept."L02BX03", 1095)
  and Reusable."HasMedicationTotalDurationWithin"({ 'BC28581100' }, 730)

define "3規則2":
"3規則2-1" and "3規則2-2"

/*規則3*/
//條件1
define "3規則3-1-1":
"ICD-C61"
and "簡要病摘-去勢抗性"
and (
    (not "3個月內有影像檢查報告" and not "3個月內有檢查報告")
    or ("3個月內有影像檢查報告" and "3個月內有檢查報告")
  )
and "M≠0"
and "PSAExtended檢驗代碼"
and "處方時間"
and "手術項目"
and "照護計畫文件資料存在"
and Reusable."醫令類別為1"

//條件2
define "3規則3-1-2-1":
exists (
    [MedicationRequest] MR
      where Reusable."HasMedicationCode"(MR, "化療藥物代碼")
        and Reusable."HasValidTiming"(MR)
        and Reusable."GetStartTime"(MR) < "本次申請起始日期"
        and Reusable."GetEndTime"(MR) < "本次申請起始日期"
  )
and Reusable."醫令類別為1"

define "3規則3-1-2-2":
exists (
    [Claim] C
      where exists (
        C.diagnosis D
          where exists (
            D.type.text T
              where Matches(T.value, '(?i).*化學治療未失敗.*')
          )
      )
  )
and Reusable."醫令類別為1"

define "3規則3-1-2":
"3規則3-1-2-1" and "3規則3-1-2-2"

define "3規則3":
"3規則3-1-1" and "3規則3-1-2"

/*規則4*/
//條件1
define "3規則4-1-1":
"ICD-C61"
and Reusable."醫令類別為1"

//條件2
// Abiraterone 給付規定：不得併用/互換藥物代碼（apalutamide、olaparib、darolutamide、enzalutamide）
define "AbirateroneExcludedConcurrentMedication":
  CodeConcept."L02BB05" union CodeConcept."L01XK01" union CodeConcept."L02BB06" union CodeConcept."L02BB04"

define "3規則4-1-2-1":
Reusable."醫令類別為1"
and not Reusable."HasMedicationRecord"("AbirateroneExcludedConcurrentMedication")

define "3規則4-1-2-2":
exists (
    [MedicationRequest] MR
      where Reusable."HasMedicationCode"(MR, "AbirateroneExcludedConcurrentMedication")
        and Reusable."HasValidTiming"(MR)
        and Reusable."GetStartTime"(MR) < "本次申請起始日期"
        and Reusable."GetEndTime"(MR) < "本次申請起始日期"
  )
and Reusable."醫令類別為1"

define "3規則4-1-2":
"3規則4-1-2-1" or "3規則4-1-2-2"

define "3規則4":
"3規則4-1-1" and "3規則4-1-2"

/*規則5*/
//條件1
define "3規則5":
  exists (
    [MedicationRequest] MR
      where Reusable."HasMedicationCode"(MR, CodeConcept."V10XX03")
        and Reusable."HasValidTiming"(MR)
        and Reusable."GetStartTime"(MR) <= "useSdate"
        and Reusable."GetEndTime"(MR) >= "useEdate"
  )
and Reusable."醫令類別為1"

define "主要規定三":
"本次申請紀錄" is not null
and "3規則1" and "3規則2" and "3規則3" and "3規則4" and not "3規則5"

//============================================
// 檢核結果用：必要資料存在判斷
//============================================

define "Abiraterone申請資料存在":
  Reusable."HasMedicationPlanRecord"(CodeConcept."L02BX03")

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
  Reusable."HasMedicationPlanTiming"(CodeConcept."L02BX03")

define "攝護腺癌ICD診斷資料存在":
  Reusable."主要疾病ICD診斷資料存在"

define "簡要病摘資料存在":
  exists (
    [Claim] C
      where exists (
        C.diagnosis D
          where exists (
            D.type.text T
              where T.value is not null
          )
      )
  )

define "影像檢查報告資料存在":
  exists (
    [DiagnosticReport] Report
      where Reusable."IsImageReport"(Report)
  )

define "分子檢查報告資料存在":
  exists (
    [DiagnosticReport] Report
      where Reusable."IsMolecularReport"(Report)
  )

define "癌症分期資料存在":
  Reusable."癌症分期資料存在"

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
        )
  )

define "去勢用藥處方資料存在":
  exists (
    [MedicationRequest] MR
      where Reusable."HasMedicationCode"(MR, "mCRPC藥物代碼")
  )

define "手術去勢處置資料存在":
  Reusable."HasSurgicalCastrationProcedure"

define "皮質類固醇處方資料存在":
  exists (
    [MedicationRequest] MR
      where Reusable."HasMedicationCode"(MR, CodeConcept."皮質類固醇藥物代碼")
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
          and Cdg.code in CodeConcept."VisceralMetastasisImageReportCode"
      )
  )

define "照護計畫文件SupportingInfo資料存在":
  Reusable."HasCarePlanDocument"

define "化療藥物處方資料存在":
  exists (
    [MedicationRequest] MR
      where Reusable."HasMedicationCode"(MR, "化療藥物代碼")
  )

define "N02M01處方資料存在":
  exists (
    [MedicationRequest] MR
      where exists (
        MR.medication.coding Cdg
          where Cdg in CodeConcept.NHIMedication
            and Cdg.code in "N02M01藥品代碼"
      )
  )

define "L01CD02處方資料存在":
  exists (
    [MedicationRequest] MR
      where Reusable."HasMedicationCode"(MR, CodeConcept."L01CD02")
  )

define "L01XK01處方資料存在":
  exists (
    [MedicationRequest] MR
      where Reusable."HasMedicationCode"(MR, CodeConcept."L01XK01")
  )

define "BRCA1_2基因突變檢測資料存在":
  exists (
    [Observation] RasO
      where exists (
        RasO.code.coding ObsCodeCoding
          where ObsCodeCoding.code = '69548-6'
            and ObsCodeCoding in CodeConcept.LOINC
      )
        and exists (
          RasO.component ComponentRecord
            where exists (
              ComponentRecord.code.coding ComponentCodeCoding
                where ComponentCodeCoding.code in CodeConcept.BRCA1_2GeneMutationTestCode
            )
        )
  )

define "V10XX03處方資料存在":
  exists (
    [MedicationRequest] MR
      where Reusable."HasMedicationCode"(MR, CodeConcept."V10XX03")
  )

define "不得併用藥物處方資料存在":
  exists (
    [MedicationRequest] MR
      where Reusable."HasMedicationCode"(MR, "AbirateroneExcludedConcurrentMedication")
  )

//============================================
// 列出「符合」項目判斷式
//============================================

define function "符合項目"():
  // 主要規定一：初次使用條件
  (if Reusable."初次申請" and (
      "1規則1" or "1規則2" or "1規則3" or "1規則4"
    )
    then '<主要規定一：初次使用條件>\n' +
         (if "1規則1" then '● 規則1：符合去勢敏感攝護腺癌初次使用條件（ICD-C61、簡要病摘、影像/檢查報告、M≠0、PSA、處方、手術、皮質類固醇併用、ECOG≦1、Gleason score或影像報告擇二、照護計畫文件、用藥線別及醫令類別）\n' else '') +
         (if "1規則2" then '● 規則2：符合去勢抗性攝護腺癌初次使用條件（含未接受過化療或使用過化學治療之簡要病摘、Gleason score、皮質類固醇併用、ECOG≦1、N02/M01 PRN止痛用藥、照護計畫文件）\n' else '') +
         (if "1規則3" then '● 規則3：符合去勢抗性攝護腺癌併用docetaxel（療程≧42天）初次使用條件（ECOG≦2、照護計畫文件）\n' else '') +
         (if "1規則4" then '● 規則4：符合與Olaparib（L01XK01）併用之BRCA1/2基因突變陽性初次使用條件（18歲以上、皮質類固醇併用）\n' else '') +
         '\n'
    else '') +

  // 主要規定二：續用條件
  (if Reusable."續用申請" and "2規則1"
    then '<主要規定二：續用條件>\n' +
         (if "2規則1" then '● 規則1：符合續用條件（ICD-C61、續用註記為2、醫令類別及PSA追蹤條件）\n' else '') +
         '\n'
    else '') +

  // 主要規定三：藥品使用規則
  (if ("3規則1" or "3規則2" or "3規則3" or "3規則4" or not "3規則5")
    then '<主要規定三：藥品使用規則>\n' +
         (if "3規則1" then '● 規則1：每次申請事前審查療程未逾3個月上限（參考資訊）\n' else '') +
         (if "3規則2" then '● 規則2：去勢敏感攝護腺癌終生總療程未逾上限（Abiraterone累計未逾1095天，特定品項未逾730天，參考資訊）\n' else '') +
         (if "3規則3" then '● 規則3：去勢抗性攝護腺癌合併化學治療條件符合（先前已完成化療，或化學治療未失敗，參考資訊）\n' else '') +
         (if "3規則4" then '● 規則4：ICD-C61且未合併使用不得併用藥物，或該藥物已於本次申請起始日前停用（參考資訊）\n' else '') +
         (if not "3規則5" then '● 規則5：未合併使用Radium-223（V10XX03）藥品（參考資訊）\n' else '') +
         '\n'
    else '')

//============================================
// 列出「不符合」項目判斷式 - 條件或代碼不符合
//============================================

define function "不符合項目_條件或代碼不符合"():
  // 主要規定一：初次使用條件 - 已提供資料但條件或代碼不符合
  (if Reusable."初次申請" and (
      (("攝護腺癌ICD診斷資料存在" and "簡要病摘資料存在") and not "1規則1")
      or (("攝護腺癌ICD診斷資料存在" and "簡要病摘資料存在") and not "1規則2")
      or (("攝護腺癌ICD診斷資料存在" and "簡要病摘資料存在") and not "1規則3")
      or (("攝護腺癌ICD診斷資料存在" and "L01XK01處方資料存在") and not "1規則4")
    )
    then '<主要規定一：初次使用條件>\n' +
         (if ("攝護腺癌ICD診斷資料存在" and "簡要病摘資料存在") and not "1規則1" then '▲ 規則1：ICD代碼、病摘、影像/檢查報告、分期、PSA、處方、手術、皮質類固醇、ECOG或Gleason/影像報告不符合去勢敏感攝護腺癌初次使用條件\n' else '') +
         (if ("攝護腺癌ICD診斷資料存在" and "簡要病摘資料存在") and not "1規則2" then '▲ 規則2：ICD代碼、病摘、化學治療紀錄、Gleason score、皮質類固醇、ECOG或N02/M01 PRN用藥不符合去勢抗性攝護腺癌初次使用條件\n' else '') +
         (if ("攝護腺癌ICD診斷資料存在" and "簡要病摘資料存在") and not "1規則3" then '▲ 規則3：ICD代碼、病摘、ECOG或docetaxel併用療程天數不符合去勢抗性攝護腺癌初次使用條件\n' else '') +
         (if ("攝護腺癌ICD診斷資料存在" and "L01XK01處方資料存在") and not "1規則4" then '▲ 規則4：ICD代碼、Olaparib處方期間、皮質類固醇或BRCA1/2基因突變檢測結果不符合初次使用條件\n' else '') +
         '\n'
    else '') +

  // 主要規定二：續用條件 - 已提供資料但條件或代碼不符合
  (if Reusable."續用申請" and (("攝護腺癌ICD診斷資料存在" and "PSA檢驗資料存在") and not "2規則1")
    then '<主要規定二：續用條件>\n' +
         '▲ 規則1：ICD代碼、續用註記、醫令類別或PSA追蹤資料不符合續用條件\n' +
         '\n'
    else '') +

  // 主要規定三：藥品使用規則 - 已提供資料但條件或代碼不符合
  (if (("療程期間資料存在" and "醫令類別資料存在" and not "3規則1")
      or (("攝護腺癌ICD診斷資料存在" and "簡要病摘資料存在") and not "3規則2")
      or (("攝護腺癌ICD診斷資料存在" and "簡要病摘資料存在") and not "3規則3")
      or ("攝護腺癌ICD診斷資料存在" and not "3規則4")
      or ("V10XX03處方資料存在" and "3規則5")
    )
    then '<主要規定三：藥品使用規則>\n' +
         (if "療程期間資料存在" and "醫令類別資料存在" and not "3規則1" then '▲ 規則1：每次申請療程超過3個月上限（參考資訊）\n' else '') +
         (if ("攝護腺癌ICD診斷資料存在" and "簡要病摘資料存在") and not "3規則2" then '▲ 規則2：去勢敏感攝護腺癌終生總療程超過上限（參考資訊）\n' else '') +
         (if ("攝護腺癌ICD診斷資料存在" and "簡要病摘資料存在") and not "3規則3" then '▲ 規則3：合併化學治療條件不符合（參考資訊）\n' else '') +
         (if "攝護腺癌ICD診斷資料存在" and not "3規則4" then '▲ 規則4：合併使用不得併用藥物，且未於本次申請起始日前停用（參考資訊）\n' else '') +
         (if "V10XX03處方資料存在" and "3規則5" then '▲ 規則5：合併使用Radium-223（V10XX03）藥品，不符合排除條件（參考資訊）\n' else '') +
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
      not "Abiraterone申請資料存在"
      or not "醫令類別資料存在"
      or not "攝護腺癌ICD診斷資料存在"
      or not "簡要病摘資料存在"
      or not "PSA檢驗資料存在"
      or (not "去勢用藥處方資料存在" and not "手術去勢處置資料存在")
      or not "皮質類固醇處方資料存在"
      or not "ECOG資料存在"
      or (not "Gleason score資料存在" and not "26029B影像報告資料存在" and not "內臟轉移影像報告資料存在")
      or not "照護計畫文件SupportingInfo資料存在"
      or not "化療藥物處方資料存在"
      or not "N02M01處方資料存在"
      or not "L01CD02處方資料存在"
      or not "L01XK01處方資料存在"
      or not "BRCA1_2基因突變檢測資料存在"
      or Patient.birthDate is null
    )
    then '<主要規定一：初次使用條件>\n' +
         (if not "Abiraterone申請資料存在" then '▲ 申請醫令：未提供Abiraterone申請醫令資料\n' else '') +
         (if not "醫令類別資料存在" then '▲ 申請醫令：未提供醫令類別資料\n' else '') +
         (if not "攝護腺癌ICD診斷資料存在" then '▲ 規則1/2/3/4：未提供主要疾病ICD診斷資料\n' else '') +
         (if not "簡要病摘資料存在" then '▲ 規則1/2/3：未提供簡要病摘資料\n' else '') +
         (if not "PSA檢驗資料存在" then '▲ 規則1/2/3：未提供PSA檢驗資料\n' else '') +
         (if not "去勢用藥處方資料存在" and not "手術去勢處置資料存在" then '▲ 規則1/2/3：未提供去勢用藥處方或手術去勢處置資料\n' else '') +
         (if not "皮質類固醇處方資料存在" then '▲ 規則1/2/3/4：未提供皮質類固醇併用處方資料\n' else '') +
         (if not "ECOG資料存在" then '▲ 規則1/2/3：未提供ECOG評估資料\n' else '') +
         (if not "Gleason score資料存在" and not "26029B影像報告資料存在" and not "內臟轉移影像報告資料存在" then '▲ 規則1/2：未提供Gleason score或影像報告資料\n' else '') +
         (if not "照護計畫文件SupportingInfo資料存在" then '▲ 規則1/2/3：未提供照護計畫文件資料\n' else '') +
         (if not "化療藥物處方資料存在" then '▲ 規則2：未提供化療藥物處方資料\n' else '') +
         (if not "N02M01處方資料存在" then '▲ 規則2：未提供N02/M01用藥資料\n' else '') +
         (if not "L01CD02處方資料存在" then '▲ 規則3：未提供docetaxel（L01CD02）處方資料\n' else '') +
         (if not "L01XK01處方資料存在" then '▲ 規則4：未提供Olaparib（L01XK01）處方資料\n' else '') +
         (if not "BRCA1_2基因突變檢測資料存在" then '▲ 規則4：未提供BRCA1/2基因突變檢測資料\n' else '') +
         (if Patient.birthDate is null then '▲ 規則1/4：未提供出生日期資料\n' else '') +
         '\n'
    else '') +

  // 主要規定二：續用條件 - 必要資料未填寫
  (if Reusable."續用申請" and (
      not "Abiraterone申請資料存在"
      or not "醫令類別資料存在"
      or not "攝護腺癌ICD診斷資料存在"
      or not "PSA檢驗資料存在"
    )
    then '<主要規定二：續用條件>\n' +
         (if not "Abiraterone申請資料存在" then '▲ 申請醫令：未提供Abiraterone申請醫令資料\n' else '') +
         (if not "醫令類別資料存在" then '▲ 申請醫令：未提供醫令類別資料\n' else '') +
         (if not "攝護腺癌ICD診斷資料存在" then '▲ 規則1：未提供主要疾病ICD診斷資料\n' else '') +
         (if not "PSA檢驗資料存在" then '▲ 規則1：未提供PSA檢驗資料\n' else '') +
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

define "攝護腺癌Abiraterone申請結果_布林":
  case
    when Reusable."初次申請" then "主要規定一"
    when Reusable."續用申請" then "主要規定二"
    else false
  end

define "攝護腺癌Abiraterone申請結果":
  if Reusable."初次申請" and "攝護腺癌Abiraterone申請結果_布林"
  then '✓通過：初次使用－攝護腺癌 Abiraterone 用藥申請'
  else if Reusable."續用申請" and "攝護腺癌Abiraterone申請結果_布林"
  then '✓通過：續用－攝護腺癌 Abiraterone 用藥申請'
  else if Reusable."初次申請"
  then '✖不通過：初次使用－攝護腺癌 Abiraterone 用藥申請'
  else if Reusable."續用申請"
  then '✖不通過：續用－攝護腺癌 Abiraterone 用藥申請'
  else '✖不通過：無法判定申請類型－攝護腺癌 Abiraterone 用藥申請'

//============================================
// 審核報告總結
//============================================

define "報告總結":
  '\n=== 攝護腺癌之Abiraterone 申請審核報告 ===\n' +
  '\n※ 備註：標示為「參考資訊」之檢核項目，係供審核參酌使用，不作為最終【申請結果】判定之依據。\n' +
  '\n【申請類型】' + Reusable."申請類型" + '\n' +
  '\n【●符合項目】\n' +
  (if "符合項目"() = '' then '無\n' else "符合項目"()) +
  '\n【▲不符合項目 - 必要資料未填寫】\n' +
  (if "不符合項目_必要資料未填寫"() = '' then '無\n' else "不符合項目_必要資料未填寫"()) +
  '\n【▲不符合項目 - 條件或代碼不符合】\n' +
  (if "不符合項目_條件或代碼不符合"() = '' then '無\n' else "不符合項目_條件或代碼不符合"()) +
  '\n【申請結果】\n' +
  "攝護腺癌Abiraterone申請結果" +
  '\n===============================================\n'