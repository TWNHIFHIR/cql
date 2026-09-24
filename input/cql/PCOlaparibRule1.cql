//攝護腺癌_Olaparib給付規定
library PCOlaparibRule1 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

include PCCodeConcept version '1.0.0' called CodeConcept

include PCReusable version '1.0.0' called Reusable

context Patient

//============================================
// 申請紀錄
//============================================

define "本次申請紀錄":
  Reusable."LatestMedicationPlan"(CodeConcept."L01XK01")

define "本次申請起始日期":
  FHIRHelpers.ToDateTime(("本次申請紀錄".dosageInstruction[0].timing.repeat.bounds as Period).start)

define "本次申請終止日期":
  FHIRHelpers.ToDateTime(("本次申請紀錄".dosageInstruction[0].timing.repeat.bounds as Period).end)

define "3個月內有影像檢查報告":
  Reusable."HasRecentImageReport"("本次申請起始日期", 90)

define "3個月內有檢查報告":
  Reusable."HasRecentMolecularReport"("本次申請起始日期", 90)

//============================================
// 主要規定一：初次使用條件
//============================================

/*規則1*/
//條件1
define "簡要病摘":
exists (
    [Claim] C
      where exists (
        C.diagnosis D
          where exists (
            D.type.text T
              where Matches(T.value, '(?i).*去勢療法無效, 曾接受過去勢治療.*')
          )
      )
  )

define "檢驗(查)名稱或套組代碼":
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
            and Cdg.code in CodeConcept."PSALabTestCode"
        )
    and Reusable."IsObservationWithinDaysBefore"(OBs, "本次申請起始日期", 90)
  )

define "賀爾蒙治療藥物代碼":
  CodeConcept."MedicalCastration" union CodeConcept."L02BX03"

define "賀爾蒙治療藥物處方時間":
  exists (
    [MedicationRequest] MR
      where Reusable."HasMedicationCode"(MR, "賀爾蒙治療藥物代碼")
        and Reusable."HasValidTiming"(MR)
        and Reusable."GetStartTime"(MR) < "本次申請終止日期"
        and Reusable."GetEndTime"(MR) < "本次申請終止日期"
  )

define "手術項目":
  Reusable."HasRecentSurgicalCastrationProcedure"("本次申請起始日期", 90)

define "1規則1-1":
Reusable."主要疾病之ICD-10使用C61"
and "簡要病摘"
and (
    (not "3個月內有影像檢查報告" and not "3個月內有檢查報告")
    or ("3個月內有影像檢查報告" and "3個月內有檢查報告")
  )
and Reusable."癌症分期分數或結果為M≠0"
and "檢驗(查)名稱或套組代碼"
and "賀爾蒙治療藥物處方時間"
and "手術項目"
and Reusable."續用註記為1"
and Reusable."醫令類別為1"

//條件2
define "1規則1-2":
not Reusable."HasConcurrentMedicationCoveringPlan"(
    CodeConcept."L01XK01",
    CodeConcept."AbirateronePrednisoneClass"
  )

//條件3
define "1規則1-3":
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
        and Matches((ComponentRecord.value as FHIR.string).value, '(?i).*(Positive|陽性|Pathogenic|致病|Likely Pathogenic|疑似致病|mutation|突變|deletion|缺失).*')
      )
  )

//條件4
define "藥物代碼":
  CodeConcept."L02BX03" union CodeConcept."L02BB05" union CodeConcept."L02BB06" union CodeConcept."L02BB04"

define "1規則1-4":
  exists (
    [MedicationRequest] MR
      where Reusable."HasMedicationCode"(MR, "藥物代碼")
        and Reusable."HasValidTiming"(MR)
        and Reusable."GetStartTime"(MR) < "本次申請終止日期"
        and Reusable."GetEndTime"(MR) < "本次申請終止日期"
  )

//條件5
define "1規則1-5":
"本次申請起始日期" is not null
  and Patient.birthDate is not null
  and AgeInYearsAt(date from "本次申請起始日期") >= 18

define "1規則1":
"1規則1-1" and "1規則1-2" and "1規則1-3" and "1規則1-4" and "1規則1-5"

/*規則2*/
//條件1
define "檢驗名稱或套組代碼":
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

define "1規則2-1":
Reusable."主要疾病之ICD-10使用C61"
and "簡要病摘"
and (
    (not "3個月內有影像檢查報告" and not "3個月內有檢查報告")
    or ("3個月內有影像檢查報告" and "3個月內有檢查報告")
  )
and Reusable."癌症分期分數或結果為M≠0"
and "檢驗名稱或套組代碼"
and "處方時間"
and "手術項目"
and Reusable."續用註記為1"
and Reusable."醫令類別為1"

//條件2
define "1規則2-2":
Reusable."HasConcurrentMedicationCoveringPlan"(
    CodeConcept."L01XK01",
    CodeConcept."L02BX03"
  )

//條件3
define "1規則2-3":
Reusable."HasConcurrentMedicationCoveringPlan"(
    CodeConcept."L01XK01",
    CodeConcept."皮質類固醇藥物代碼"
  )

//條件4
define "1規則2-4":
"1規則1-3"

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

define "化學治療藥物代碼":
  CodeConcept."L01CD" union CodeConcept."L01AA01" union CodeConcept."L01DB07"

define "未使用化學治療藥物":
  not exists (
    [MedicationRequest] MR
      where Reusable."HasMedicationCode"(MR, "化學治療藥物代碼")
        and Reusable."HasValidTiming"(MR)
        and Reusable."GetStartTime"(MR) < "本次申請終止日期"
        and Reusable."GetEndTime"(MR) < "本次申請終止日期"
  )

define "1規則2-5":
"簡要病摘-未接受過化療" and "未使用化學治療藥物"

//條件6
define "1規則2-6":
"1規則1-5"

//條件7
define "1規則2-7-1":
not Reusable."HasMedicationRecord"("藥物代碼")

define "簡要病摘-未惡化":
exists (
    [Claim] C
      where exists (
        C.diagnosis D
          where exists (
            D.type.text T
              where Matches(T.value, '(?i).*於mCRPC階段使用abiraterone期間未惡化.*')
          )
      )
  )

define "OlaparibRule3藥物代碼":
  CodeConcept."L02BX03"

define "OlaparibRule3處方期間符合":
  exists (
    [MedicationRequest] MR
      where Reusable."HasMedicationCode"(MR, "OlaparibRule3藥物代碼")
        and Reusable."HasValidTiming"(MR)
        and (duration in months between Reusable."GetStartTime"(MR) and Reusable."GetEndTime"(MR)) < 4
  )

define "1規則2-7-2":
 "簡要病摘-未惡化" and "OlaparibRule3處方期間符合"

define "1規則2-7":
"1規則2-7-1" or "1規則2-7-2"

define "1規則2":
"1規則2-1" and "1規則2-2" and "1規則2-3" and "1規則2-4" and "1規則2-5" and "1規則2-6" and "1規則2-7"

/*規則3*/
//條件1
define "1規則3-1":
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
      )
      and exists (
        RasO.derivedFrom Ref
        where Ref.reference is not null
      )
  )

//條件2
define "照護計畫文件資料存在":
  Reusable."HasCarePlanDocument"
  and (
    exists ([MedicationRequest])
    or exists (
      [Claim] C
        where exists (
          C.procedure P
            where P.procedure is FHIR.CodeableConcept
              and exists (
                ((P.procedure as FHIR.CodeableConcept).coding) Cdg
                  where Cdg.code in CodeConcept.SurgicalCastrationOPCode
              )
        )
    )
  )

define "1規則3-2":
"3個月內有檢查報告"
and "檢驗名稱或套組代碼"
and "處方時間"
and "手術項目"
and "照護計畫文件資料存在"

define "1規則3":
"1規則3-1" and "1規則3-2"

define "主要規定一":
"本次申請紀錄" is not null
and  ("1規則1" or ("1規則2" and "1規則3"))

//============================================
// 主要規定二：續用條件
//============================================

/*規則1*/
//條件1
define "前次申請紀錄":
  Reusable."LatestMedicationPlanBefore"(CodeConcept."L01XK01", "本次申請起始日期")

define "前次申請起始日期":
  Reusable."GetStartTime"("前次申請紀錄")

define "檢驗代碼":
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
        and Reusable."IsObservationAfter"(OBs, "前次申請起始日期")
  )

define "2規則1-1":
"檢驗代碼"
and Reusable."續用註記為2"
and Reusable."醫令類別為1"

//條件2
define "2規則1-2-1":
"2規則1-1"

define "2規則1-2-2":
"2規則1-1"

define "前次申請後有影像檢查報告":
"前次申請起始日期" is not null
and Reusable."HasImageReportAfter"("前次申請起始日期")

define "2規則1-2-3":
"前次申請後有影像檢查報告"
and "2規則1-1"

define "2規則1-2":
"2規則1-2-1" and "2規則1-2-2" or "2規則1-2-3"

define "主要規定二":
"本次申請紀錄" is not null
and ("2規則1-1" or "2規則1-2")

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
define "3規則2-1":
Reusable."醫令類別為1"
and Reusable."HasConcurrentDailyDoseAtMost"(CodeConcept.L01XK01, 4, '{tbl}', 'QD')

/*規則3*/
//條件1
define "簡要病摘-未合併使用化療":
exists (
    [Claim] C
      where exists (
        C.diagnosis D
          where exists (
            D.type.text T
              where Matches(T.value, '(?i).*未合併使用化療.*')
          )
      )
  )

define "化療藥物處方期間涵蓋本次申請期間":
  exists (
    [MedicationRequest] MR
      where Reusable."HasMedicationCode"(MR, "化學治療藥物代碼")
        and Reusable."HasValidTiming"(MR)
        and Reusable."GetStartTime"(MR) <= "本次申請起始日期"
        and Reusable."GetEndTime"(MR) >= "本次申請終止日期"
  )

define "3規則3-1":
"簡要病摘-未合併使用化療"
and "化療藥物處方期間涵蓋本次申請期間"
and Reusable."醫令類別為1"

/*規則4*/
//條件1
define "併用mCRPC藥物期間涵蓋本次申請期間":
  Reusable."HasConcurrentMedicationCoveringPlan"(
    CodeConcept."L01XK01",
    CodeConcept."mCRPC治療藥物代碼2"
  )

define "併用Abiraterone藥物期間涵蓋本次申請期間":
  Reusable."HasConcurrentMedicationCoveringPlan"(
    CodeConcept."L01XK01",
    CodeConcept."Abiraterone藥物代碼"
  )

define "併用皮質類固醇藥物期間涵蓋本次申請期間":
  Reusable."HasConcurrentMedicationCoveringPlan"(
    CodeConcept."L01XK01",
    CodeConcept."皮質類固醇藥物代碼"
  )

define "併用藥品代碼":
  "併用mCRPC藥物期間涵蓋本次申請期間"
  and "併用Abiraterone藥物期間涵蓋本次申請期間"
  and "併用皮質類固醇藥物期間涵蓋本次申請期間"

define "3規則4-1-1":
Reusable."主要疾病之ICD-10使用C61"
and "簡要病摘"
and (
    (not "3個月內有影像檢查報告" and not "3個月內有檢查報告")
    or ("3個月內有影像檢查報告" and "3個月內有檢查報告")
  )
and Reusable."癌症分期分數或結果為M≠0"
and "檢驗名稱或套組代碼"
and "併用藥品代碼"
and "手術項目"
and "1規則1-3"
and Reusable."續用註記為1"

//條件2
define "3規則4-1-2-1":
not Reusable."HasMedicationRecord"("藥物代碼")

define "簡要病摘-無法忍受副作用":
exists (
    [Claim] C
      where exists (
        C.diagnosis D
          where exists (
            D.type.text T
              where Matches(T.value, '(?i).*無法忍受新型荷爾蒙藥品(abiraterone、apalutamide、darolutamide 和 enzalutamide)副作用.*')
          )
      )
  )

define "指定藥物處方時間早於本次申請起始日期":
  exists (
    [MedicationRequest] MR
      where Reusable."HasMedicationCode"(MR, "藥物代碼")
        and Reusable."HasValidTiming"(MR)
        and Reusable."GetStartTime"(MR) < "本次申請起始日期"
        and Reusable."GetEndTime"(MR) < "本次申請起始日期"
  )

define "3規則4-1-2-2":
"簡要病摘-無法忍受副作用" and "指定藥物處方時間早於本次申請起始日期"

define "3規則4-1-2":
"3規則4-1-2-1" or "3規則4-1-2-2"

define "3規則4-1":
"3規則4-1-1" and  "3規則4-1-2"

define "主要規定三":
"本次申請紀錄" is not null
and "3規則1-1" and "3規則2-1" and "3規則3-1" and "3規則4-1"


//============================================
// 檢核結果用：必要資料存在判斷
//============================================

define "Olaparib申請資料存在":
  Reusable."HasMedicationPlanRecord"(CodeConcept."L01XK01")

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
  Reusable."HasMedicationPlanTiming"(CodeConcept."L01XK01")

define "攝護腺癌ICD診斷資料存在":
  Reusable."主要疾病ICD診斷資料存在"

define "病摘資料存在":
  exists (
    [Claim] C
      where exists (
        C.diagnosis D
          where D.type.text is not null
      )
  )

define "影像或檢查報告資料存在":
  exists (
    [DiagnosticReport] Report
      where Reusable."IsImageReport"(Report)
        or Reusable."IsMolecularReport"(Report)
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

define "賀爾蒙治療藥物用藥資料存在":
  Reusable."HasMedicationRecord"("賀爾蒙治療藥物代碼")

define "手術項目資料存在":
  Reusable."HasSurgicalCastrationProcedure"

define "BRCA基因檢測資料存在":
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

define "新型荷爾蒙藥物用藥資料存在":
  Reusable."HasMedicationRecord"("藥物代碼")

define "mCRPC治療藥物用藥資料存在":
  Reusable."HasMedicationRecord"("mCRPC藥物代碼")

define "化學治療藥物用藥資料存在":
  Reusable."HasMedicationRecord"("化學治療藥物代碼")

define "L02BX03用藥資料存在":
  Reusable."HasMedicationRecord"(CodeConcept."L02BX03")

define "AbirateronePrednisoneClass用藥資料存在":
  Reusable."HasMedicationRecord"(CodeConcept."AbirateronePrednisoneClass")

define "皮質類固醇藥物用藥資料存在":
  Reusable."HasMedicationRecord"(CodeConcept."皮質類固醇藥物代碼")

define "併用藥品資料存在":
  Reusable."HasMedicationRecord"(CodeConcept."mCRPC治療藥物代碼2")
  or Reusable."HasMedicationRecord"(CodeConcept."Abiraterone藥物代碼")
  or Reusable."HasMedicationRecord"(CodeConcept."皮質類固醇藥物代碼")

define "出生日期資料存在":
  Patient.birthDate is not null

define "前次申請紀錄資料存在":
  "前次申請紀錄" is not null

//============================================
// 列出「符合」項目判斷式
//============================================

define function "符合項目"():
  // 主要規定一：初次使用條件
  (if Reusable."初次申請" and (
      "1規則1-1" or "1規則1-2" or "1規則1-3" or "1規則1-4" or "1規則1-5"
      or "1規則2-1" or "1規則2-2" or "1規則2-3" or "1規則2-5" or "1規則2-7"
      or "1規則3-1" or "1規則3-2"
    )
    then '<主要規定一：初次使用條件>\n' +
      (if "1規則1-1" then '● 規則1-1：ICD診斷、病摘、影像/檢查報告、癌症分期、PSA檢驗、賀爾蒙治療藥物處方時間、手術項目、續用註記及醫令類別皆符合條件\n' else '') +
      (if "1規則1-2" then '● 規則1-2：未併用abiraterone/prednisone等指定藥物涵蓋本次申請期間\n' else '') +
      (if "1規則1-3" then '● 規則1-3/2-4：具BRCA1/2基因致病性或疑似致病性突變檢驗結果\n' else '') +
      (if "1規則1-4" then '● 規則1-4：新型荷爾蒙藥物處方時間早於本次申請終止日期\n' else '') +
      (if "1規則1-5" then '● 規則1-5/2-6：年齡滿18歲\n' else '') +
      (if "1規則2-1" then '● 規則2-1：ICD診斷、病摘、影像/檢查報告、癌症分期、PSA檢驗（擴充版）、mCRPC藥物處方時間、手術項目、續用註記及醫令類別皆符合條件\n' else '') +
      (if "1規則2-2" then '● 規則2-2：併用L02BX03藥物期間涵蓋本次申請期間\n' else '') +
      (if "1規則2-3" then '● 規則2-3：併用皮質類固醇藥物期間涵蓋本次申請期間\n' else '') +
      (if "1規則2-5" then '● 規則2-5：病摘載明未接受過化療且無化學治療藥物用藥紀錄\n' else '') +
      (if "1規則2-7" then '● 規則2-7：未曾使用過指定新型荷爾蒙藥物，或病摘載明使用abiraterone期間未惡化且處方期間未滿4個月\n' else '') +
      (if "1規則3-1" then '● 規則3-1：BRCA檢測報告具derivedFrom引用資料\n' else '') +
      (if "1規則3-2" then '● 規則3-2：符合檢查報告、PSA檢驗、mCRPC藥物處方時間、手術項目及照護計畫文件條件\n' else '') +
      '\n'
    else '') +

  // 主要規定二：續用條件
  (if Reusable."續用申請" and ("2規則1-1" or "2規則1-2")
    then '<主要規定二：續用條件>\n' +
      (if "2規則1-1" then '● 規則1-1：PSA檢驗（基本版）晚於前次申請起始日期、續用註記為2及醫令類別為1\n' else '') +
      (if "2規則1-2" then '● 規則1-2：符合續用檢驗條件，且（如適用）前次申請後有影像檢查報告\n' else '') +
      '\n'
    else '') +

  // 主要規定三：藥品使用規則
  (if ("3規則1-1" or "3規則2-1" or "3規則3-1" or "3規則4-1")
    then '<主要規定三：藥品使用規則>\n' +
      (if "3規則1-1" then '● 規則3-1：本次申請療程未逾3個月且醫令類別為1（參考資訊）\n' else '') +
      (if "3規則2-1" then '● 規則3-2：Olaparib每日劑量未超過4錠（參考資訊）\n' else '') +
      (if "3規則3-1" then '● 規則3-3：病摘及化療藥物處方期間涵蓋本次申請期間條件符合（參考資訊）\n' else '') +
      (if "3規則4-1" then '● 規則3-4：符合併用藥品、BRCA檢測及未使用過指定藥物（或無法忍受副作用）等續用條件（參考資訊）\n' else '') +
      '\n'
    else '')


//============================================
// 列出「不符合」項目判斷式 - 條件或代碼不符合
//============================================

define function "不符合項目_條件或代碼不符合"():
  // 主要規定一：初次使用條件 - 已提供資料但條件或代碼不符合
  (if Reusable."初次申請" and (
      (("攝護腺癌ICD診斷資料存在" and "病摘資料存在" and "PSA檢驗資料存在" and "賀爾蒙治療藥物用藥資料存在" and "手術項目資料存在" and "醫令類別資料存在") and not "1規則1-1")
      or ("AbirateronePrednisoneClass用藥資料存在" and not "1規則1-2")
      or ("BRCA基因檢測資料存在" and not "1規則1-3")
      or ("新型荷爾蒙藥物用藥資料存在" and not "1規則1-4")
      or ("出生日期資料存在" and not "1規則1-5")
      or (("攝護腺癌ICD診斷資料存在" and "病摘資料存在" and "PSA檢驗資料存在" and "mCRPC治療藥物用藥資料存在" and "手術項目資料存在" and "醫令類別資料存在") and not "1規則2-1")
      or ("L02BX03用藥資料存在" and not "1規則2-2")
      or ("皮質類固醇藥物用藥資料存在" and not "1規則2-3")
      or (("病摘資料存在" or "化學治療藥物用藥資料存在") and not "1規則2-5")
      or (("新型荷爾蒙藥物用藥資料存在" or "病摘資料存在") and not "1規則2-7")
      or ("BRCA基因檢測資料存在" and not "1規則3-1")
      or (("影像或檢查報告資料存在" and "PSA檢驗資料存在" and "mCRPC治療藥物用藥資料存在" and "手術項目資料存在" and "照護計畫文件資料存在") and not "1規則3-2")
    )
    then '<主要規定一：初次使用條件>\n' +
      (if ("攝護腺癌ICD診斷資料存在" and "病摘資料存在" and "PSA檢驗資料存在" and "賀爾蒙治療藥物用藥資料存在" and "手術項目資料存在" and "醫令類別資料存在") and not "1規則1-1" then '▲ 規則1-1：ICD診斷、病摘、影像/檢查報告、癌症分期、PSA檢驗、賀爾蒙治療藥物處方時間、手術項目、續用註記或醫令類別條件不符合\n' else '') +
      (if "AbirateronePrednisoneClass用藥資料存在" and not "1規則1-2" then '▲ 規則1-2：合併使用abiraterone/prednisone等指定藥物涵蓋本次申請期間\n' else '') +
      (if "BRCA基因檢測資料存在" and not "1規則1-3" then '▲ 規則1-3/2-4：BRCA1/2基因檢驗結果非致病性或疑似致病性突變\n' else '') +
      (if "新型荷爾蒙藥物用藥資料存在" and not "1規則1-4" then '▲ 規則1-4：新型荷爾蒙藥物處方時間未早於本次申請終止日期\n' else '') +
      (if "出生日期資料存在" and not "1規則1-5" then '▲ 規則1-5/2-6：年齡未滿18歲\n' else '') +
      (if ("攝護腺癌ICD診斷資料存在" and "病摘資料存在" and "PSA檢驗資料存在" and "mCRPC治療藥物用藥資料存在" and "手術項目資料存在" and "醫令類別資料存在") and not "1規則2-1" then '▲ 規則2-1：ICD診斷、病摘、影像/檢查報告、癌症分期、PSA檢驗（擴充版）、mCRPC藥物處方時間、手術項目、續用註記或醫令類別條件不符合\n' else '') +
      (if "L02BX03用藥資料存在" and not "1規則2-2" then '▲ 規則2-2：併用L02BX03藥物期間未涵蓋本次申請期間\n' else '') +
      (if "皮質類固醇藥物用藥資料存在" and not "1規則2-3" then '▲ 規則2-3：併用皮質類固醇藥物期間未涵蓋本次申請期間\n' else '') +
      (if ("病摘資料存在" or "化學治療藥物用藥資料存在") and not "1規則2-5" then '▲ 規則2-5：病摘未載明未接受過化療，或已有化學治療藥物用藥紀錄\n' else '') +
      (if ("新型荷爾蒙藥物用藥資料存在" or "病摘資料存在") and not "1規則2-7" then '▲ 規則2-7：已有新型荷爾蒙藥物使用紀錄，且病摘未載明使用abiraterone期間未惡化或處方期間未滿4個月\n' else '') +
      (if "BRCA基因檢測資料存在" and not "1規則3-1" then '▲ 規則3-1：BRCA檢測報告未具derivedFrom引用資料\n' else '') +
      (if ("影像或檢查報告資料存在" and "PSA檢驗資料存在" and "mCRPC治療藥物用藥資料存在" and "手術項目資料存在" and "照護計畫文件資料存在") and not "1規則3-2" then '▲ 規則3-2：檢查報告、PSA檢驗、mCRPC藥物處方時間、手術項目或照護計畫文件條件不符合\n' else '') +
      '\n'
    else '') +

  // 主要規定二：續用條件 - 已提供資料但條件或代碼不符合
  (if Reusable."續用申請" and (
      (("Olaparib申請資料存在" and "PSA檢驗資料存在") and not "2規則1-1")
      or (("Olaparib申請資料存在" and "PSA檢驗資料存在") and not "2規則1-2")
    )
    then '<主要規定二：續用條件>\n' +
      (if ("Olaparib申請資料存在" and "PSA檢驗資料存在") and not "2規則1-1" then '▲ 規則1-1：PSA檢驗（基本版）未晚於前次申請起始日期，或續用註記/醫令類別不符合\n' else '') +
      (if ("Olaparib申請資料存在" and "PSA檢驗資料存在") and not "2規則1-2" then '▲ 規則1-2：續用檢驗或影像檢查報告條件不符合\n' else '') +
      '\n'
    else '') +

  // 主要規定三：藥品使用規則 - 已提供資料但條件或代碼不符合
  (if "療程期間資料存在" and (
      not "3規則1-1"
      or not "3規則2-1"
      or (("病摘資料存在" and "化學治療藥物用藥資料存在") and not "3規則3-1")
      or (("併用藥品資料存在" and "BRCA基因檢測資料存在") and not "3規則4-1")
    )
    then '<主要規定三：藥品使用規則>\n' +
      (if not "3規則1-1" then '▲ 規則3-1：本次申請療程逾3個月或醫令類別不為1（參考資訊）\n' else '') +
      (if not "3規則2-1" then '▲ 規則3-2：Olaparib每日劑量超過4錠（參考資訊）\n' else '') +
      (if ("病摘資料存在" and "化學治療藥物用藥資料存在") and not "3規則3-1" then '▲ 規則3-3：病摘或化療藥物處方期間涵蓋本次申請期間條件不符合（參考資訊）\n' else '') +
      (if ("併用藥品資料存在" and "BRCA基因檢測資料存在") and not "3規則4-1" then '▲ 規則3-4：併用藥品、BRCA檢測或未使用過指定藥物（無法忍受副作用）等續用條件不符合（參考資訊）\n' else '') +
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
      not "Olaparib申請資料存在"
      or not "醫令類別資料存在"
      or not "攝護腺癌ICD診斷資料存在"
      or not "病摘資料存在"
      or not "影像或檢查報告資料存在"
      or not "癌症分期資料存在"
      or not "PSA檢驗資料存在"
      or not "賀爾蒙治療藥物用藥資料存在"
      or not "手術項目資料存在"
      or not "BRCA基因檢測資料存在"
      or not "出生日期資料存在"
      or not "照護計畫文件資料存在"
    )
    then '<主要規定一：初次使用條件>\n' +
      (if not "Olaparib申請資料存在" then '▲ 申請醫令：未提供Olaparib申請醫令資料\n' else '') +
      (if not "醫令類別資料存在" then '▲ 申請醫令：未提供醫令類別資料\n' else '') +
      (if not "攝護腺癌ICD診斷資料存在" then '▲ 規則1-1/2-1：未提供主要疾病ICD診斷資料\n' else '') +
      (if not "病摘資料存在" then '▲ 規則1-1/2-1/2-5：未提供病摘資料\n' else '') +
      (if not "影像或檢查報告資料存在" then '▲ 規則1-1/2-1/3-2：未提供影像或檢查報告資料\n' else '') +
      (if not "癌症分期資料存在" then '▲ 規則1-1/2-1：未提供癌症分期分數或結果資料\n' else '') +
      (if not "PSA檢驗資料存在" then '▲ 規則1-1/2-1/3-2：未提供PSA檢驗資料\n' else '') +
      (if not "賀爾蒙治療藥物用藥資料存在" then '▲ 規則1-1：未提供賀爾蒙治療藥物用藥紀錄\n' else '') +
      (if not "手術項目資料存在" then '▲ 規則1-1/2-1/3-2：未提供手術去勢項目資料\n' else '') +
      (if not "BRCA基因檢測資料存在" then '▲ 規則1-3/2-4/3-1：未提供BRCA1/2基因檢測資料\n' else '') +
      (if not "出生日期資料存在" then '▲ 規則1-5/2-6：未提供病人出生日期資料\n' else '') +
      (if not "照護計畫文件資料存在" then '▲ 規則3-2：未提供照護計畫文件資料\n' else '') +
      '\n'
    else '') +

  // 主要規定二：續用條件 - 必要資料未填寫
  (if Reusable."續用申請" and (
      not "Olaparib申請資料存在"
      or not "PSA檢驗資料存在"
    )
    then '<主要規定二：續用條件>\n' +
      (if not "Olaparib申請資料存在" then '▲ 申請醫令：未提供Olaparib申請醫令資料\n' else '') +
      (if not "PSA檢驗資料存在" then '▲ 規則1-1/1-2：未提供PSA檢驗資料\n' else '') +
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

define "攝護腺癌Olaparib申請結果_布林":
  case
    when Reusable."初次申請" then "主要規定一"
    when Reusable."續用申請" then "主要規定二"
    else false
  end

define "攝護腺癌Olaparib申請結果":
  if Reusable."初次申請" and "攝護腺癌Olaparib申請結果_布林"
  then '✓通過：初次使用－攝護腺癌 Olaparib 用藥申請'
  else if Reusable."續用申請" and "攝護腺癌Olaparib申請結果_布林"
  then '✓通過：續用－攝護腺癌 Olaparib 用藥申請'
  else if Reusable."初次申請"
  then '✖不通過：初次使用－攝護腺癌 Olaparib 用藥申請'
  else if Reusable."續用申請"
  then '✖不通過：續用－攝護腺癌 Olaparib 用藥申請'
  else '✖不通過：無法判定申請類型－攝護腺癌 Olaparib 用藥申請'


//============================================
// 審核報告總結
//============================================

define "報告總結":
  '\n=== 攝護腺癌之Olaparib 申請審核報告 ===\n' +
  '\n※ 備註：標示為「參考資訊」之檢核項目，係供審核參酌使用，不作為最終【申請結果】判定之依據。\n' +
  '\n【申請類型】' + Reusable."申請類型" + '\n' +
  '\n【●符合項目】\n' +
  (if "符合項目"() = '' then '無\n' else "符合項目"()) +
  '\n【▲不符合項目 - 必要資料未填寫】\n' +
  (if "不符合項目_必要資料未填寫"() = '' then '無\n' else "不符合項目_必要資料未填寫"()) +
  '\n【▲不符合項目 - 條件或代碼不符合】\n' +
  (if "不符合項目_條件或代碼不符合"() = '' then '無\n' else "不符合項目_條件或代碼不符合"()) +
  '\n【申請結果】\n' +
  "攝護腺癌Olaparib申請結果" +
  '\n===============================================\n'