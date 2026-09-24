//攝護腺癌_Apalutamide給付規定
library PCApalutamideRule1 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

include PCCodeConcept version '1.0.0' called CodeConcept

include PCReusable version '1.0.0' called Reusable

context Patient

//============================================
// 申請紀錄
//============================================
define "本次申請紀錄":
  Reusable."LatestMedicationPlan"(CodeConcept."L02BB05")

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

define "M=0":
  Reusable."癌症分期分數或結果為M=0"

//============================================
// 主要規定一：初次使用條件
//============================================

/*規則1*/
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
and "簡要病摘-去勢抗性"
and (
    (not "3個月內有影像檢查報告" and not "3個月內有檢查報告")
    or ("3個月內有影像檢查報告" and "3個月內有檢查報告")
  )
and "M=0"
and "PSAExtended檢驗代碼"
and "處方時間"
and "手術項目"
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
define "照護計畫文件資料存在":
  Reusable."HasCarePlanDocument"
  and (
    Reusable."HasMedicationRecord"("mCRPC藥物代碼")
    or "手術項目"
  )

define "1規則1-4":
"3個月內有檢查報告"
and "PSAExtended檢驗代碼"
and "處方時間"
and "手術項目"
and "照護計畫文件資料存在"

//條件5
define "1規則1-5":
"3個月內有影像檢查報告"

//條件6
define "1規則1-6":
  Reusable."HasRecentECOGAtMost"(1, "本次申請起始日期", 90)

//條件7
define "PSABasic檢驗代碼":
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

define "1規則1-7-1":
"PSABasic檢驗代碼"

define "1規則1-7-2":
"PSABasic檢驗代碼"

define "1規則1-7-3":
"PSABasic檢驗代碼"

define "1規則1-7-4":
"PSABasic檢驗代碼"

define "1規則1-7":
"1規則1-7-1" and "1規則1-7-2" and "1規則1-7-3" and "1規則1-7-4"

define "1規則1":
"1規則1-1" and "1規則1-2" and "1規則1-3" and "1規則1-4" and "1規則1-5" and "1規則1-6" and "1規則1-7"

/*規則2*/
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

define "1規則2-1":
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
and Reusable."續用註記為1"
and Reusable."醫令類別為1"

//條件2
define "Gleason score≧8":
  Reusable."HasGleasonScoreAtLeast8"

define "1規則2-2-2":
"Gleason score≧8"

define "3個月內有26029B影像報告":
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

define "1規則2-2-3":
"3個月內有26029B影像報告"

define "3個月內有內臟轉移影像報告":
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

define "1規則2-2-4":
"3個月內有內臟轉移影像報告"

define "1規則2-2":
("1規則2-2-2" and "1規則2-2-3")
or ("1規則2-2-2" and "1規則2-2-4")
or ("1規則2-2-3" and "1規則2-2-4")

define "1規則2":
"1規則2-1" and "1規則2-2"

define "主要規定一":
"本次申請紀錄" is not null
and ( "1規則1" or "1規則2" )

//============================================
// 主要規定二：續用條件
//============================================

/*規則1*/
//條件1
define "2規則1-1":
"ICD-C61"
and "簡要病摘-去勢抗性"
and (
    (not "3個月內有影像檢查報告" and not "3個月內有檢查報告")
    or ("3個月內有影像檢查報告" and "3個月內有檢查報告")
  )
and "M=0"
and "PSAExtended檢驗代碼"
and "處方時間"
and "手術項目"
and Reusable."續用註記為2"
and Reusable."醫令類別為1"

//條件2
define "2規則1-2":
"本次申請起始日期" is not null
  and Patient.birthDate is not null
  and AgeInYearsAt(date from "本次申請起始日期") >= 18

//條件3
define "2規則1-3":
Patient.gender.value = 'male'

//條件4
define "2規則1-4-1":
"PSABasic檢驗代碼"

define "2規則1-4-2":
"3個月內有影像檢查報告"

define "2規則1-4-3":
Reusable."HasRecentImageReport"("本次申請起始日期", 180)

define "2規則1-4":
if "2規則1-4-1" then "2規則1-4-2" else "2規則1-4-3"

define "2規則1":
"2規則1-1" and "2規則1-2" and "2規則1-3" and "2規則1-4"

/*規則2*/
//條件1
define "2規則2-1":
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
and Reusable."續用註記為2"
and Reusable."醫令類別為1"

//條件2
define "2規則2-2-1":
"PSABasic檢驗代碼"

define "2規則2-2-2-1":
"PSABasic檢驗代碼"

define "2規則2-2-2-2":
"PSABasic檢驗代碼"

define "2規則2-2-2-3":
"PSABasic檢驗代碼"

define "2規則2-2-2":
("2規則2-2-2-1" and "2規則2-2-2-2")
or "2規則2-2-2-3"

define "2規則2-2":
"2規則2-2-1" or "2規則2-2-2"

define "2規則2":
"2規則2-1" and "2規則2-2"

define "主要規定二":
"本次申請紀錄" is not null
and ( "2規則1" or "2規則2" )

//============================================
// 主要規定三：藥品使用規則
//============================================

/*規則1*/
//條件1
define "3規則1-1":
"本次申請起始日期" is not null
and "本次申請終止日期" is not null
and (duration in months between "本次申請起始日期" and "本次申請終止日期") <= 3
and Reusable."醫令類別為1"

/*規則2*/
//條件1
define "終生總療程以36個月為上限":
  Reusable."HasMedicationTotalDurationWithin"(CodeConcept."L02BB05", 1095)


define "3規則2-1":
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
and Reusable."醫令類別為1"
and "終生總療程以36個月為上限"

/*規則3*/
//條件1
define "3規則3-1-1":
"ICD-C61"

define "3規則3-1-2-1":
Reusable."醫令類別為1"
and not Reusable."HasMedicationRecord"(CodeConcept."ApalutamideExcludedConcurrentMedication")

define "簡要病摘-無法忍受副作用":
exists (
    [Claim] C
      where exists (
        C.diagnosis D
          where exists (
            D.type.text T
              where Matches(T.value, '(?i).*無法忍受新型荷爾蒙藥品(abiraterone、darolutamide 和 enzalutamide) ，及 olaparib 與 abiraterone 併用副作用.*')
          )
      )
  )

define "Apalutamide不得併用藥物處方時間":
  exists (
    [MedicationRequest] MR
      where Reusable."HasMedicationCode"(MR, CodeConcept."ApalutamideExcludedConcurrentMedication")
        and Reusable."HasValidTiming"(MR)
        and Reusable."GetStartTime"(MR) < "本次申請起始日期"
        and Reusable."GetEndTime"(MR) < "本次申請起始日期"
  )

define "3規則3-1-2-2":
"簡要病摘-無法忍受副作用"
and "Apalutamide不得併用藥物處方時間"
and Reusable."醫令類別為1"

define "3規則3-1-2":
"3規則3-1-2-1" or "3規則3-1-2-2"

define "3規則3-1":
"3規則3-1-1" and "3規則3-1-2"

define "主要規定三":
"本次申請紀錄" is not null
and "3規則1-1" and "3規則2-1" and "3規則3-1"

//============================================
// 檢核結果用：必要資料存在判斷
//============================================

define "Apalutamide申請資料存在":
  Reusable."HasMedicationPlanRecord"(CodeConcept."L02BB05")

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
  Reusable."HasMedicationPlanTiming"(CodeConcept."L02BB05")

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

//============================================
// 列出「符合」項目判斷式
//============================================

define function "符合項目"():
  // 主要規定一：初次使用條件
  (if Reusable."初次申請" and (
      "1規則1-1" or "1規則1-2" or "1規則1-3" or "1規則1-4" or "1規則1-5" or "1規則1-6" or "1規則1-7"
      or "1規則2-1" or "1規則2-2"
    )
    then '<主要規定一：初次使用條件>\n' +
         (if "1規則1-1" then '● 規則1-1：符合去勢抗性攝護腺癌初次使用條件（ICD-C61、簡要病摘、影像/檢查報告、M=0、PSA、處方、手術、續用註記、醫令類別）\n' else '') +
         (if "1規則1-2" then '● 規則1-2：符合18歲以上成人條件\n' else '') +
         (if "1規則1-3" then '● 規則1-3：符合男性條件\n' else '') +
         (if "1規則1-4" then '● 規則1-4：符合照護計畫文件及治療紀錄條件\n' else '') +
         (if "1規則1-5" then '● 規則1-5：三個月內有影像檢查報告\n' else '') +
         (if "1規則1-6" then '● 規則1-6：符合ECOG≦1條件\n' else '') +
         (if "1規則1-7" then '● 規則1-7：符合PSA檢驗資料條件\n' else '') +
         (if "1規則2-1" then '● 規則2-1：符合去勢敏感攝護腺癌初次使用條件（ICD-C61、簡要病摘、影像/檢查報告、M≠0、PSA、處方、手術、續用註記、醫令類別）\n' else '') +
         (if "1規則2-2" then '● 規則2-2：符合Gleason score≧8及影像報告條件（26029B、內臟轉移報告擇二）\n' else '') +
         '\n'
    else '') +

  // 主要規定二：續用條件
  (if Reusable."續用申請" and (
      "2規則1-1" or "2規則1-2" or "2規則1-3" or "2規則1-4"
      or "2規則2-1" or "2規則2-2"
    )
    then '<主要規定二：續用條件>\n' +
         (if "2規則1-1" then '● 規則1-1：符合去勢抗性攝護腺癌續用條件\n' else '') +
         (if "2規則1-2" then '● 規則1-2：符合18歲以上成人條件\n' else '') +
         (if "2規則1-3" then '● 規則1-3：符合男性條件\n' else '') +
         (if "2規則1-4" then '● 規則1-4：符合PSA檢驗或影像追蹤條件\n' else '') +
         (if "2規則2-1" then '● 規則2-1：符合去勢敏感攝護腺癌續用條件\n' else '') +
         (if "2規則2-2" then '● 規則2-2：符合PSA追蹤條件\n' else '') +
         '\n'
    else '') +

  // 主要規定三：藥品使用規則
  (if ("3規則1-1" or "3規則2-1" or "3規則3-1")
    then '<主要規定三：藥品使用規則>\n' +
         (if "3規則1-1" then '● 規則3-1：每次申請事前審查療程以3個月為限（參考資訊）\n' else '') +
         (if "3規則2-1" then '● 規則3-2：去勢敏感攝護腺癌終生總療程未逾36個月（參考資訊）\n' else '') +
         (if "3規則3-1" then '● 規則3-3：符合ICD-C61且無不得併用藥物，或已符合無法忍受副作用轉換條件（參考資訊）\n' else '') +
         '\n'
    else '')

//============================================
// 列出「不符合」項目判斷式 - 條件或代碼不符合
//============================================

define function "不符合項目_條件或代碼不符合"():
  // 主要規定一：初次使用條件 - 已提供資料但條件或代碼不符合
  (if Reusable."初次申請" and (
      (("攝護腺癌ICD診斷資料存在" and "簡要病摘資料存在") and not "1規則1-1")
      or (Patient.birthDate is not null and not "1規則1-2")
      or (Patient.gender.value is not null and not "1規則1-3")
      or (("分子檢查報告資料存在" or "PSA檢驗資料存在" or "去勢用藥處方資料存在" or "手術去勢處置資料存在") and not "1規則1-4")
      or ("影像檢查報告資料存在" and not "1規則1-5")
      or ("ECOG資料存在" and not "1規則1-6")
      or ("PSA檢驗資料存在" and not "1規則1-7")
      or (("攝護腺癌ICD診斷資料存在" and "簡要病摘資料存在") and not "1規則2-1")
      or (("Gleason score資料存在" or "26029B影像報告資料存在" or "內臟轉移影像報告資料存在") and not "1規則2-2")
    )
    then '<主要規定一：初次使用條件>\n' +
         (if ("攝護腺癌ICD診斷資料存在" and "簡要病摘資料存在") and not "1規則1-1" then '▲ 規則1-1：ICD代碼、病摘、影像/檢查報告、分期、PSA、處方或手術紀錄不符合去勢抗性攝護腺癌初次使用條件\n' else '') +
         (if Patient.birthDate is not null and not "1規則1-2" then '▲ 規則1-2：年齡未滿18歲\n' else '') +
         (if Patient.gender.value is not null and not "1規則1-3" then '▲ 規則1-3：性別非男性\n' else '') +
         (if ("分子檢查報告資料存在" or "PSA檢驗資料存在" or "去勢用藥處方資料存在" or "手術去勢處置資料存在") and not "1規則1-4" then '▲ 規則1-4：檢查報告、PSA、處方、手術或照護計畫文件不符合條件\n' else '') +
         (if "影像檢查報告資料存在" and not "1規則1-5" then '▲ 規則1-5：影像檢查報告日期不在本次申請起始日前三個月內\n' else '') +
         (if "ECOG資料存在" and not "1規則1-6" then '▲ 規則1-6：ECOG評估結果不符合≦1條件\n' else '') +
         (if "PSA檢驗資料存在" and not "1規則1-7" then '▲ 規則1-7：PSA檢驗代碼不符合指定清單\n' else '') +
         (if ("攝護腺癌ICD診斷資料存在" and "簡要病摘資料存在") and not "1規則2-1" then '▲ 規則2-1：ICD代碼、病摘、影像/檢查報告、分期、PSA、處方或手術紀錄不符合去勢敏感攝護腺癌初次使用條件\n' else '') +
         (if ("Gleason score資料存在" or "26029B影像報告資料存在" or "內臟轉移影像報告資料存在") and not "1規則2-2" then '▲ 規則2-2：Gleason score或影像報告不符合條件\n' else '') +
         '\n'
    else '') +

  // 主要規定二：續用條件 - 已提供資料但條件或代碼不符合
  (if Reusable."續用申請" and (
      (("攝護腺癌ICD診斷資料存在" and "簡要病摘資料存在") and not "2規則1-1")
      or (Patient.birthDate is not null and not "2規則1-2")
      or (Patient.gender.value is not null and not "2規則1-3")
      or ("PSA檢驗資料存在" and not "2規則1-4")
      or (("攝護腺癌ICD診斷資料存在" and "簡要病摘資料存在") and not "2規則2-1")
      or ("PSA檢驗資料存在" and not "2規則2-2")
    )
    then '<主要規定二：續用條件>\n' +
         (if ("攝護腺癌ICD診斷資料存在" and "簡要病摘資料存在") and not "2規則1-1" then '▲ 規則1-1：ICD代碼、病摘、影像/檢查報告、分期、PSA、處方或手術紀錄不符合去勢抗性攝護腺癌續用條件\n' else '') +
         (if Patient.birthDate is not null and not "2規則1-2" then '▲ 規則1-2：年齡未滿18歲\n' else '') +
         (if Patient.gender.value is not null and not "2規則1-3" then '▲ 規則1-3：性別非男性\n' else '') +
         (if "PSA檢驗資料存在" and not "2規則1-4" then '▲ 規則1-4：PSA檢驗或影像追蹤資料不符合續用條件\n' else '') +
         (if ("攝護腺癌ICD診斷資料存在" and "簡要病摘資料存在") and not "2規則2-1" then '▲ 規則2-1：ICD代碼、病摘、影像/檢查報告、分期、PSA、處方或手術紀錄不符合去勢敏感攝護腺癌續用條件\n' else '') +
         (if "PSA檢驗資料存在" and not "2規則2-2" then '▲ 規則2-2：PSA追蹤資料不符合續用條件\n' else '') +
         '\n'
    else '') +

  // 主要規定三：藥品使用規則 - 已提供資料但條件或代碼不符合
  (if (("療程期間資料存在" and "醫令類別資料存在" and not "3規則1-1")
      or (("攝護腺癌ICD診斷資料存在" and "簡要病摘資料存在") and not "3規則2-1")
      or ("攝護腺癌ICD診斷資料存在" and not "3規則3-1")
    )
    then '<主要規定三：藥品使用規則>\n' +
         (if "療程期間資料存在" and "醫令類別資料存在" and not "3規則1-1" then '▲ 規則3-1：每次申請療程超過3個月上限（參考資訊）\n' else '') +
         (if ("攝護腺癌ICD診斷資料存在" and "簡要病摘資料存在") and not "3規則2-1" then '▲ 規則3-2：去勢敏感攝護腺癌終生總療程超過36個月上限（參考資訊）\n' else '') +
         (if "攝護腺癌ICD診斷資料存在" and not "3規則3-1" then '▲ 規則3-3：合併使用不得併用藥物，且未符合無法忍受副作用轉換條件（參考資訊）\n' else '') +
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
      not "Apalutamide申請資料存在"
      or not "醫令類別資料存在"
      or not "攝護腺癌ICD診斷資料存在"
      or not "簡要病摘資料存在"
      or not "PSA檢驗資料存在"
      or (not "去勢用藥處方資料存在" and not "手術去勢處置資料存在")
      or not "影像檢查報告資料存在"
      or not "ECOG資料存在"
      or (not "Gleason score資料存在" and not "26029B影像報告資料存在" and not "內臟轉移影像報告資料存在")
    )
    then '<主要規定一：初次使用條件>\n' +
         (if not "Apalutamide申請資料存在" then '▲ 申請醫令：未提供Apalutamide申請醫令資料\n' else '') +
         (if not "醫令類別資料存在" then '▲ 申請醫令：未提供醫令類別資料\n' else '') +
         (if not "攝護腺癌ICD診斷資料存在" then '▲ 規則1-1/2-1：未提供主要疾病ICD診斷資料\n' else '') +
         (if not "簡要病摘資料存在" then '▲ 規則1-1/2-1：未提供簡要病摘資料\n' else '') +
         (if not "PSA檢驗資料存在" then '▲ 規則1-1/1-7/2-1：未提供PSA檢驗資料\n' else '') +
         (if not "去勢用藥處方資料存在" and not "手術去勢處置資料存在" then '▲ 規則1-1/2-1：未提供去勢用藥處方或手術去勢處置資料\n' else '') +
         (if not "影像檢查報告資料存在" then '▲ 規則1-5：未提供三個月內影像檢查報告資料\n' else '') +
         (if not "ECOG資料存在" then '▲ 規則1-6：未提供ECOG評估資料\n' else '') +
         (if not "Gleason score資料存在" and not "26029B影像報告資料存在" and not "內臟轉移影像報告資料存在" then '▲ 規則2-2：未提供Gleason score或影像報告資料\n' else '') +
         '\n'
    else '') +

  // 主要規定二：續用條件 - 必要資料未填寫
  (if Reusable."續用申請" and (
      not "Apalutamide申請資料存在"
      or not "醫令類別資料存在"
      or not "攝護腺癌ICD診斷資料存在"
      or not "簡要病摘資料存在"
      or not "PSA檢驗資料存在"
      or (not "去勢用藥處方資料存在" and not "手術去勢處置資料存在")
    )
    then '<主要規定二：續用條件>\n' +
         (if not "Apalutamide申請資料存在" then '▲ 申請醫令：未提供Apalutamide申請醫令資料\n' else '') +
         (if not "醫令類別資料存在" then '▲ 申請醫令：未提供醫令類別資料\n' else '') +
         (if not "攝護腺癌ICD診斷資料存在" then '▲ 規則1-1/2-1：未提供主要疾病ICD診斷資料\n' else '') +
         (if not "簡要病摘資料存在" then '▲ 規則1-1/2-1：未提供簡要病摘資料\n' else '') +
         (if not "PSA檢驗資料存在" then '▲ 規則1-4/2-2：未提供PSA檢驗資料\n' else '') +
         (if not "去勢用藥處方資料存在" and not "手術去勢處置資料存在" then '▲ 規則1-1/2-1：未提供去勢用藥處方或手術去勢處置資料\n' else '') +
         '\n'
    else '') +

  // 主要規定三：藥品使用規則 - 必要資料未填寫
  (if not "療程期間資料存在"
    then '<主要規定三：藥品使用規則>\n' +
         '▲ 規則3-1：未提供療程起迄日期資料（參考資訊）\n' +
         '\n'
    else '')

//============================================
// 審核結果
//============================================

define "攝護腺癌Apalutamide申請結果_布林":
  case
    when Reusable."初次申請" then "主要規定一"
    when Reusable."續用申請" then "主要規定二"
    else false
  end

define "攝護腺癌Apalutamide申請結果":
  if Reusable."初次申請" and "攝護腺癌Apalutamide申請結果_布林"
  then '✓通過：初次使用－攝護腺癌 Apalutamide 用藥申請'
  else if Reusable."續用申請" and "攝護腺癌Apalutamide申請結果_布林"
  then '✓通過：續用－攝護腺癌 Apalutamide 用藥申請'
  else if Reusable."初次申請"
  then '✖不通過：初次使用－攝護腺癌 Apalutamide 用藥申請'
  else if Reusable."續用申請"
  then '✖不通過：續用－攝護腺癌 Apalutamide 用藥申請'
  else '✖不通過：無法判定申請類型－攝護腺癌 Apalutamide 用藥申請'

//============================================
// 審核報告總結
//============================================

define "報告總結":
  '\n=== 攝護腺癌之Apalutamide 申請審核報告 ===\n' +
  '\n※ 備註：標示為「參考資訊」之檢核項目，係供審核參酌使用，不作為最終【申請結果】判定之依據。\n' +
  '\n【申請類型】' + Reusable."申請類型" + '\n' +
  '\n【●符合項目】\n' +
  (if "符合項目"() = '' then '無\n' else "符合項目"()) +
  '\n【▲不符合項目 - 必要資料未填寫】\n' +
  (if "不符合項目_必要資料未填寫"() = '' then '無\n' else "不符合項目_必要資料未填寫"()) +
  '\n【▲不符合項目 - 條件或代碼不符合】\n' +
  (if "不符合項目_條件或代碼不符合"() = '' then '無\n' else "不符合項目_條件或代碼不符合"()) +
  '\n【申請結果】\n' +
  "攝護腺癌Apalutamide申請結果" +
  '\n===============================================\n'