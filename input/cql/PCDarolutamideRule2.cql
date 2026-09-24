//攝護腺癌_Darolutamide給付規定-治療高風險非轉移性去勢抗性前列腺癌(high risk nmCRPC)的成年男性
library PCDarolutamideRule2 version '1.0.0'

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

//============================================
// 主要規定一：初次使用條件
//============================================

/*規則1*/
//條件1
define "1規則1-2-2":
  Reusable."HasGleasonScoreAtLeast8"

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

define "1規則1-1":
("1規則1-2-2" and "1規則1-2-3")
or ("1規則1-2-2" and "1規則1-2-4")
or ("1規則1-2-3" and "1規則1-2-4")

//條件2
define "成年":
"本次申請起始日期" is not null
  and Patient.birthDate is not null
  and AgeInYearsAt(date from "本次申請起始日期") >= 18

define "男性":
Patient.gender.value = 'male'

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

define "1規則1-2":
"成年"
and "男性"
and "ICD-C61"
and (
    (not "3個月內有影像檢查報告" and not "3個月內有檢查報告")
    or ("3個月內有影像檢查報告" and "3個月內有檢查報告")
  )
and Reusable."癌症分期分數或結果為M=0"
and "檢驗代碼"
and Reusable."續用註記為1"
and Reusable."醫令類別為1"

define "1規則1":
"1規則1-1" and "1規則1-2"

/*規則2*/
//條件1
define "去勢用藥代碼":
  CodeConcept."L02AE" union CodeConcept."L02BX02"

define "有去勢用藥處方":
  exists (
    [MedicationRequest] MR
      where Reusable."HasMedicationCode"(MR, "去勢用藥代碼")
  )

define "手術去勢處置項目":
  Reusable."HasRecentSurgicalCastrationProcedure"("本次申請起始日期", 90)

define "檢查報告66117-3":
  [DiagnosticReport] Report
    where exists (
      Report.code.coding Cdg
        where Cdg in CodeConcept.LOINC
          and Cdg.code = '66117-3'
    )

define "檢查報告資料存在":
  exists ("檢查報告66117-3")

define "1規則2":
(
  (not "3個月內有影像檢查報告" and not "3個月內有檢查報告")
  or ("3個月內有影像檢查報告" and "3個月內有檢查報告")
)
and "檢查報告資料存在"
and "檢驗代碼"
and "有去勢用藥處方"
and "手術去勢處置項目"

define "主要規定一":
"本次申請紀錄" is not null
and "1規則1" and "1規則2"

//============================================
// 主要規定二：續用條件
//============================================

/*規則1*/
//條件1
define "2規則1-1":
"本次申請起始日期" is not null
and "本次申請終止日期" is not null
and ((duration in days between "本次申請起始日期" and "本次申請終止日期") / 28) <= 3
and Reusable."續用註記為2"
and Reusable."醫令類別為1"

/*規則2*/
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

//報告時效:至少要有3筆PSA數值
define "PSA檢驗數值至少3筆":
  Count("PSA檢驗清單") >= 3

//去重後的PSA檢驗報告日期(僅取日期,不含時間)
define "PSA檢驗日期清單":
  distinct (
    "PSA檢驗清單" OBs
      return date from Reusable."EffectiveDateTime"(OBs.effective)
  )

//檢驗(查)報告日期:至少要有3個不同的檢驗日期
define "PSA檢驗報告日期至少3筆":
  Count("PSA檢驗日期清單") >= 3

//依日期由舊到新排序之PSA檢驗日期清單
define "PSA日期舊到新清單":
  ("PSA檢驗日期清單") D
    sort asc

//依日期由舊到新排序,取各日期之PSA數值(同一天有多筆時取最大值)
define "PSA依日期排序清單":
  ("PSA日期舊到新清單") D
    return Max(
      "PSA檢驗清單" OBs
        where date from Reusable."EffectiveDateTime"(OBs.effective) = D
        return (OBs.value as FHIR.Quantity).value
    )

//依日期排序清單之總筆數
define "PSA清單筆數":
  Count("PSA依日期排序清單")

//最近3個檢驗日期中最早一筆之PSA數值(第一筆)
define "第一筆PSA":
  "PSA依日期排序清單"[("PSA清單筆數") - 3]

//最近3個檢驗日期中居中一筆之PSA數值(第二筆)
define "第二筆PSA":
  "PSA依日期排序清單"[("PSA清單筆數") - 2]

//最近3個檢驗日期中最新一筆之PSA數值(第三筆)
define "第三筆PSA":
  "PSA依日期排序清單"[("PSA清單筆數") - 1]

//檢驗(查)結果條件1:(第二筆PSA-第一筆PSA)/第二筆PSA >= 25%
define "PSA上升幅度達25%":
  "第一筆PSA" is not null
  and "第二筆PSA" is not null
  and "第二筆PSA" > 0
  and (("第二筆PSA" - "第一筆PSA") / "第二筆PSA") >= 0.25

//檢驗(查)結果條件2:第二筆PSA >= 2 ng/mL
define "第二筆PSA達2ngmL以上":
  "第二筆PSA" is not null
  and "第二筆PSA" >= 2

//檢驗(查)結果條件3:第三筆PSA > 第二筆PSA,才有上升趨勢
define "PSA持續上升趨勢":
  "第三筆PSA" is not null
  and "第二筆PSA" is not null
  and "第三筆PSA" > "第二筆PSA"

define "PSA上升趨勢條件成立":
"PSA檢驗數值至少3筆"
and "PSA檢驗報告日期至少3筆"
and "PSA上升幅度達25%"
and "第二筆PSA達2ngmL以上"
and "PSA持續上升趨勢"

define "2規則2-1":
"3個月內有影像檢查報告" and "PSA上升趨勢條件成立"

//條件2
//檢驗(查)結果條件1:(第二筆PSA-第一筆PSA)/第二筆PSA < 25%
define "PSA上升幅度未達25%":
  "第一筆PSA" is not null
  and "第二筆PSA" is not null
  and "第二筆PSA" > 0
  and (("第二筆PSA" - "第一筆PSA") / "第二筆PSA") < 0.25

//檢驗(查)結果條件2:第二筆PSA < 2 ng/mL
define "第二筆PSA未達2ngmL":
  "第二筆PSA" is not null
  and "第二筆PSA" < 2

//檢驗(查)結果條件3:第三筆PSA < 第二筆PSA
define "第三筆PSA低於第二筆":
  "第三筆PSA" is not null
  and "第二筆PSA" is not null
  and "第三筆PSA" < "第二筆PSA"

define "PSA未持續上升趨勢":
"PSA檢驗數值至少3筆"
and "PSA檢驗報告日期至少3筆"
and ( "PSA上升幅度未達25%"
or "第二筆PSA未達2ngmL"
or "第三筆PSA低於第二筆" )

define "2規則2-2":
Reusable."HasRecentImageReport"("本次申請起始日期", 180)
and "PSA未持續上升趨勢"

define "2規則2":
"2規則2-1" or "2規則2-2"

define "主要規定二":
"本次申請紀錄" is not null
and "2規則1-1" and "2規則2"

//============================================
// 主要規定三：藥品使用規則
//============================================

/*規則1*/
//條件1
define "3規則1":
  Reusable."HasECOGAtMost"(1)

/*規則2*/
//條件2
//PSA數值清單
define "PSA數值清單":
  "PSA檢驗清單" OBs
    return (OBs.value as FHIR.Quantity).value

//最高的PSA數值
define "PSA最高值":
  Max("PSA數值清單")

//檢驗(查)結果:PSA >= 0.2 ng/mL(最高的PSA值必須 > 1.0 ng/mL)
define "PSA結果符合條件":
  exists ("PSA數值清單" V where V >= 0.2)
  and "PSA最高值" is not null
  and "PSA最高值" > 1.0

//綜合條件
define "3規則2-2":
"PSA檢驗數值至少3筆"
and "PSA檢驗報告日期至少3筆"
and "PSA結果符合條件"

//條件3
define "本次用藥期間PSA檢驗清單":
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
      and OBs.effective is not null
      and Reusable."EffectiveDateTime"(OBs.effective) >= "本次申請起始日期"
      and Reusable."EffectiveDateTime"(OBs.effective) <= "本次申請終止日期"

define "3規則2-3":
exists ("本次用藥期間PSA檢驗清單")
and "有去勢用藥處方"

//條件4
define "PSA最早檢驗日期":
  Min("PSA檢驗日期清單")

define "PSA最晚檢驗日期":
  Max("PSA檢驗日期清單")

define "PSA檢驗報告日期週數":
  (duration in days between "PSA最早檢驗日期" and "PSA最晚檢驗日期") / 7

define "3規則2-4":
  "PSA檢驗日期清單" is not null
  and Count("PSA檢驗日期清單") >= 2
  and "PSA檢驗報告日期週數" between 8 and 12

define "3規則2":
"3規則2-2" and "3規則2-3" and "3規則2-4"

/*規則3*/
//條件1
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

define "3規則3":
Reusable."續用註記為1"
and Reusable."醫令類別為1"
and not ( "有Abiraterone處方"
or "有Apalutamide處方"
or "有Enzalutamide處方"
or "Olaparib與Abiraterone併用" )

define "主要規定三":
"本次申請紀錄" is not null
and "3規則1" and "3規則2" and "3規則3"

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

//============================================
// 列出「符合」項目判斷式
//============================================

define function "符合項目"():
  // 主要規定一：初次使用條件
  (if Reusable."初次申請" and (
      "1規則1" or "1規則2"
    )
    then '<主要規定一：初次使用條件>\n' +
         (if "1規則1" then '● 規則1：Gleason score≧8、26029B影像報告、內臟轉移影像報告三項擇二，且成年男性、ICD-C61、影像/檢查報告、M=0、PSA及睪固酮檢驗、續用註記與醫令類別符合條件\n' else '') +
         (if "1規則2" then '● 規則2：影像/檢查報告、基因檢查報告(66117-3)、PSA及睪固酮檢驗、去勢用藥處方或手術去勢處置符合條件\n' else '') +
         '\n'
    else '') +

  // 主要規定二：續用條件
  (if Reusable."續用申請" and (
      "2規則1-1" or "2規則2"
    )
    then '<主要規定二：續用條件>\n' +
         (if "2規則1-1" then '● 續用規則1：每次申請事前審查之療程以3個月為限，且申請註記與醫令類別符合條件\n' else '') +
         (if "2規則2" then '● 續用規則2：3個月內影像檢查報告且PSA持續上升趨勢，或6個月內影像檢查報告且PSA未持續上升趨勢\n' else '') +
         '\n'
    else '') +

  // 主要規定三：藥品使用規則
  (if ("3規則1" or "3規則2" or "3規則3")
    then '<主要規定三：藥品使用規則>\n' +
         (if "3規則1" then '● 規則1：ECOG PS≦1（參考資訊）\n' else '') +
         (if "3規則2" then '● 規則2：PSA檢驗筆數、用藥期間PSA數值及檢驗報告間隔週數（8-12週）符合條件（參考資訊）\n' else '') +
         (if "3規則3" then '● 規則3：未併用Abiraterone、Apalutamide、Enzalutamide或Olaparib與Abiraterone併用（參考資訊）\n' else '') +
         '\n'
    else '')

//============================================
// 列出「不符合」項目判斷式 - 條件或代碼不符合
//============================================

define function "不符合項目_條件或代碼不符合"():
  // 主要規定一：初次使用條件 - 已提供資料但條件或代碼不符合
  (if Reusable."初次申請" and (
      (("Gleason score資料存在" or "26029B影像報告資料存在" or "內臟轉移影像報告資料存在") and not "1規則1")
      or (("檢查報告資料存在" and "PSA檢驗資料存在" and "睪固酮檢驗資料存在") and not "1規則2")
    )
    then '<主要規定一：初次使用條件>\n' +
         (if ("Gleason score資料存在" or "26029B影像報告資料存在" or "內臟轉移影像報告資料存在") and not "1規則1" then '▲ 規則1：Gleason score、影像報告或成年男性、ICD、分期、檢驗代碼、續用註記、醫令類別不符合條件\n' else '') +
         (if ("檢查報告資料存在" and "PSA檢驗資料存在" and "睪固酮檢驗資料存在") and not "1規則2" then '▲ 規則2：影像/檢查報告、基因檢查報告、PSA或睪固酮檢驗、去勢用藥處方或手術去勢處置不符合條件\n' else '') +
         '\n'
    else '') +

  // 主要規定二：續用條件 - 已提供資料但條件或代碼不符合
  (if Reusable."續用申請" and (
      ("療程期間資料存在" and not "2規則1-1")
      or ("PSA檢驗資料存在" and not "2規則2")
    )
    then '<主要規定二：續用條件>\n' +
         (if "療程期間資料存在" and not "2規則1-1" then '▲ 續用規則1：療程超過3個月上限，或申請註記、醫令類別不符合條件\n' else '') +
         (if "PSA檢驗資料存在" and not "2規則2" then '▲ 續用規則2：PSA檢驗筆數、日期或上升趨勢不符合續用規則2條件\n' else '') +
         '\n'
    else '') +

  // 主要規定三：藥品使用規則 - 已提供資料但條件或代碼不符合
  (if (("ECOG資料存在" and not "3規則1")
      or ("PSA檢驗資料存在" and not "3規則2")
      or ("攝護腺癌ICD診斷資料存在" and not "3規則3")
    )
    then '<主要規定三：藥品使用規則>\n' +
         (if "ECOG資料存在" and not "3規則1" then '▲ 規則1：ECOG評估結果不符合PS≦1（參考資訊）\n' else '') +
         (if "PSA檢驗資料存在" and not "3規則2" then '▲ 規則2：PSA檢驗筆數、用藥期間PSA數值或檢驗報告間隔週數不符合條件（參考資訊）\n' else '') +
         (if "攝護腺癌ICD診斷資料存在" and not "3規則3" then '▲ 規則3：合併使用Abiraterone、Apalutamide、Enzalutamide，或Olaparib與Abiraterone併用（參考資訊）\n' else '') +
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
      or (not "Gleason score資料存在" and not "26029B影像報告資料存在" and not "內臟轉移影像報告資料存在")
      or not "PSA檢驗資料存在"
      or not "睪固酮檢驗資料存在"
      or (not "有去勢用藥處方" and not "手術去勢處置資料存在")
      or not "檢查報告資料存在"
    )
    then '<主要規定一：初次使用條件>\n' +
         (if not "Darolutamide申請資料存在" then '▲ 申請醫令：未提供Darolutamide申請醫令資料\n' else '') +
         (if not "醫令類別資料存在" then '▲ 申請醫令：未提供醫令類別資料\n' else '') +
         (if not "攝護腺癌ICD診斷資料存在" then '▲ 規則1：未提供主要疾病ICD診斷資料\n' else '') +
         (if not "Gleason score資料存在" and not "26029B影像報告資料存在" and not "內臟轉移影像報告資料存在" then '▲ 規則1：未提供Gleason score或影像報告資料\n' else '') +
         (if not "PSA檢驗資料存在" then '▲ 規則1/2：未提供PSA檢驗資料\n' else '') +
         (if not "睪固酮檢驗資料存在" then '▲ 規則1/2：未提供睪固酮檢驗資料\n' else '') +
         (if not "有去勢用藥處方" and not "手術去勢處置資料存在" then '▲ 規則2：未提供去勢用藥處方或手術去勢處置資料\n' else '') +
         (if not "檢查報告資料存在" then '▲ 規則2：未提供基因檢查報告(66117-3)資料\n' else '') +
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
         (if not "PSA檢驗資料存在" then '▲ 續用規則2：未提供PSA檢驗資料\n' else '') +
         '\n'
    else '') +

  // 主要規定三：藥品使用規則 - 必要資料未填寫
  (if not "療程期間資料存在"
    then '<主要規定三：藥品使用規則>\n' +
         '▲ 續用規則1：未提供療程起迄日期資料（參考資訊）\n' +
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
  '\n=== 攝護腺癌之Darolutamide（治療high risk nmCRPC）申請審核報告 ===\n' +
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
