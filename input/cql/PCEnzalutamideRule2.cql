//攝護腺癌_Enzalutamide給付規定-高風險轉移性的去勢敏感性前列腺癌(mCSPC) 
library PCEnzalutamideRule2 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

include PCCodeConcept version '1.0.0' called CodeConcept

include PCReusable version '1.0.0' called Reusable

context Patient

//============================================
// 申請紀錄
//============================================

define "本次申請紀錄":
  Reusable."LatestMedicationPlan"(CodeConcept."L02BB04限Xtandi")

define "本次申請起始日期":
  FHIRHelpers.ToDateTime(("本次申請紀錄".dosageInstruction[0].timing.repeat.bounds as Period).start)

define "本次申請終止日期":
  FHIRHelpers.ToDateTime(("本次申請紀錄".dosageInstruction[0].timing.repeat.bounds as Period).end)

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
              where Matches(T.value, '(?i).*轉移性的去勢敏感性前列腺癌(mCSPC).*')
          )
      )
  )

define "檢驗代碼-PSA":
  exists (
    [Observation] OBs
      where exists (
        OBs.code.coding Cdg
          where Cdg in CodeConcept.LOINC
            and Cdg.code in CodeConcept."PSACode"
      )
  )

define "1規則1-1":
Reusable."主要疾病之ICD-10使用C61"
and "簡要病摘-去勢敏感"
and Reusable."癌症分期分數或結果為M≠0"
and "檢驗代碼-PSA"
and Reusable."續用註記為1"

/*規則2*/
//條件2
define "併用mCRPC治療藥物期間落於本次申請期間內":
  Reusable."HasConcurrentMedicationOrderWithinPlan"(
    CodeConcept."L02BB04限Xtandi",
    CodeConcept."mCRPC治療藥物代碼2"
  )

define "手術項目<useEdate":
  Reusable."HasSurgicalCastrationProcedureBefore"("本次申請終止日期")

define "1規則2-2":
"併用mCRPC治療藥物期間落於本次申請期間內"
  or "手術項目<useEdate"

/*規則3*/
//條件3
define "1規則3-3-1":
  Reusable."HasGleasonScoreAtLeast8"

define "1規則3-3-2":
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

define "1規則3-3-3":
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
)

define "1規則3":
("1規則3-3-1" and "1規則3-3-2")
or ("1規則3-3-1" and "1規則3-3-3")
or ("1規則3-3-2" and "1規則3-3-3")

define "主要規定一":
"本次申請紀錄" is not null
and "1規則1-1" and "1規則2-2" and "1規則3"

//============================================
// 主要規定二：續用條件
//============================================

/*規則1*/
//條件1
define "3個月內有檢查報告":
  Reusable."HasRecentMolecularReport"("本次申請起始日期", 84)

define "2規則1-1":
"3個月內有檢查報告"
and Reusable."續用註記為2"

//條件2
define "2規則1-2-1":
  Reusable."HasSurgicalCastrationProcedureBefore"("本次申請起始日期")

define "指定停用藥物代碼":
  CodeConcept."L02AE" union CodeConcept."L02BX02" union CodeConcept."L02BB"

define "近6個月內曾終止之指定藥物":
  exists (
    [MedicationRequest] MR
      where Reusable."HasMedicationCode"(MR, "指定停用藥物代碼")
        and Reusable."HasValidTiming"(MR)
        and Reusable."GetEndTime"(MR) <= "本次申請起始日期"
        and (months between Reusable."GetEndTime"(MR) and "本次申請起始日期") <= 6
  )

define "2規則1-2-2":
 "近6個月內曾終止之指定藥物"

define "2規則1-2":
 "2規則1-2-1" or "2規則1-2-2"

//條件3
define "2規則1-3":
"檢驗代碼-PSA"

//條件4
define "2規則1-4":
  exists (
    [Observation] OBs
      where exists (
        OBs.code.coding Cdg
          where Cdg in CodeConcept.LOINC
            and Cdg.code in CodeConcept."TestosteroneCode"
      )
  )

//條件5
define "2規則1-5":
"檢驗代碼-PSA"

//條件6
define "2規則1-6":
Reusable."HasRecentImageReport"("本次申請起始日期", 90)
and "檢驗代碼-PSA"

define "2規則1":
"2規則1-1" and "2規則1-2" and "2規則1-3" and "2規則1-4" and "2規則1-5" and "2規則1-6"

define "主要規定二":
"本次申請紀錄" is not null
and "2規則1"

//============================================
// 主要規定三：藥品使用規則
//============================================

/*規則1*/
//條件1
define "3規則1-2-1":
not exists (
    [MedicationRequest] MR
      where Reusable."HasMedicationCode"(MR, CodeConcept."EnzalutamideExcludedConcurrentMedication")
        and Reusable."HasValidTiming"(MR)
  )

define "3規則1-2-2":
exists (
    [Claim] C
      where exists (
        C.diagnosis D
          where exists (
            D.type.text T
              where Matches(T.value, '(?i).*嚴重不耐受反應導致必須永久停止治療.*')
          )
      )
  )

define "3規則1-1":
  if "3規則1-2-1" then true
  else "3規則1-2-2"  

/*規則2*/
//條件2
//事前審查藥物(Enzalutamide)預定處方起始日期(useSdate)
define "useSdate":
  "本次申請起始日期"

//事前審查藥物(Enzalutamide)預定處方終止日期(useEdate)
define "useEdate":
  "本次申請終止日期"

define "3規則2-2":
  not exists (
    [MedicationRequest] MR
      where Reusable."HasMedicationCode"(MR, CodeConcept."V10XX03")
        and Reusable."HasValidTiming"(MR)
        and "useSdate" <= Reusable."GetEndTime"(MR)
        and "useEdate" >= Reusable."GetStartTime"(MR)
  )

define "主要規定三":
"本次申請紀錄" is not null
and "3規則1-1" and "3規則2-2"

//============================================
// 檢核結果用：必要資料存在判斷
//============================================

define "Enzalutamide申請資料存在":
  Reusable."HasMedicationPlanRecord"(CodeConcept."L02BB04限Xtandi")

define "療程期間資料存在":
  Reusable."HasMedicationPlanTiming"(CodeConcept."L02BB04限Xtandi")

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

define "癌症分期資料存在":
  Reusable."癌症分期資料存在"

define "PSA檢驗資料存在":
  exists (
    [Observation] OBs
      where exists (
        OBs.code.coding Cdg
          where Cdg in CodeConcept.LOINC
            and Cdg.code in CodeConcept."PSACode"
      )
  )

define "mCRPC治療藥物處方資料存在":
  exists (
    [MedicationRequest] MR
      where Reusable."HasMedicationCode"(MR, CodeConcept."mCRPC治療藥物代碼2")
  )

define "手術去勢處置資料存在":
  Reusable."HasSurgicalCastrationProcedure"

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

define "Radium223無內臟轉移影像報告資料存在":
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
  )

define "分子檢查報告資料存在":
  exists (
    [DiagnosticReport] Report
      where Reusable."IsMolecularReport"(Report)
  )

define "睪固酮檢驗資料存在":
  exists (
    [Observation] OBs
      where exists (
        OBs.code.coding Cdg
          where Cdg in CodeConcept.LOINC
            and Cdg.code in CodeConcept."TestosteroneCode"
      )
  )

define "影像檢查報告資料存在":
  exists (
    [DiagnosticReport] Report
      where Reusable."IsImageReport"(Report)
  )

define "指定停用藥物處方資料存在":
  exists (
    [MedicationRequest] MR
      where Reusable."HasMedicationCode"(MR, "指定停用藥物代碼")
  )

define "不得併用藥物處方資料存在":
  exists (
    [MedicationRequest] MR
      where Reusable."HasMedicationCode"(MR, CodeConcept."EnzalutamideExcludedConcurrentMedication")
  )

define "V10XX03處方資料存在":
  exists (
    [MedicationRequest] MR
      where Reusable."HasMedicationCode"(MR, CodeConcept."V10XX03")
  )

//============================================
// 列出「符合」項目判斷式
//============================================

define function "符合項目"():
  // 主要規定一：初次使用條件
  (if Reusable."初次申請" and "主要規定一"
    then '<主要規定一：初次使用條件>\n' +
         (if "1規則1-1" then '● 規則1：符合ICD-C61、簡要病摘（轉移性去勢敏感性前列腺癌mCSPC）、癌症分期M≠0、PSA檢驗及續用註記為1之初次使用條件\n' else '') +
         (if "1規則2-2" then '● 規則2：符合併用mCRPC治療藥物期間落於本次申請期間內，或手術去勢時間早於本次申請終止日期之條件\n' else '') +
         (if "1規則3" then '● 規則3：符合Gleason score≧8與26029B影像報告或Radium-223無內臟轉移影像報告擇二之條件\n' else '') +
         '\n'
    else '') +

  // 主要規定二：續用條件
  (if Reusable."續用申請" and "主要規定二"
    then '<主要規定二：續用條件>\n' +
         (if "2規則1" then '● 規則1：符合3個月內檢查報告、續用註記為2、手術去勢或近6個月內終止指定藥物、PSA檢驗、睪固酮檢驗及影像檢查報告之續用條件\n' else '') +
         '\n'
    else '') +

  // 主要規定三：藥品使用規則
  (if ("3規則1-1" or "3規則2-2")
    then '<主要規定三：藥品使用規則>\n' +
         (if "3規則1-1" then '● 規則1：未合併使用不得併用藥物，或已因嚴重不耐受反應永久停止治療（參考資訊）\n' else '') +
         (if "3規則2-2" then '● 規則2：本次申請期間未合併使用Radium-223（V10XX03）藥品（參考資訊）\n' else '') +
         '\n'
    else '')

//============================================
// 列出「不符合」項目判斷式 - 條件或代碼不符合
//============================================

define function "不符合項目_條件或代碼不符合"():
  // 主要規定一：初次使用條件 - 已提供資料但條件或代碼不符合
  (if Reusable."初次申請" and (
      (("攝護腺癌ICD診斷資料存在" and "簡要病摘資料存在") and not "1規則1-1")
      or (("mCRPC治療藥物處方資料存在" or "手術去勢處置資料存在") and not "1規則2-2")
      or (("Gleason score資料存在" or "26029B影像報告資料存在" or "Radium223無內臟轉移影像報告資料存在") and not "1規則3")
    )
    then '<主要規定一：初次使用條件>\n' +
         (if ("攝護腺癌ICD診斷資料存在" and "簡要病摘資料存在") and not "1規則1-1" then '▲ 規則1：ICD代碼、簡要病摘、癌症分期或PSA檢驗結果不符合初次使用條件\n' else '') +
         (if ("mCRPC治療藥物處方資料存在" or "手術去勢處置資料存在") and not "1規則2-2" then '▲ 規則2：併用mCRPC治療藥物期間或手術去勢時間不符合條件\n' else '') +
         (if ("Gleason score資料存在" or "26029B影像報告資料存在" or "Radium223無內臟轉移影像報告資料存在") and not "1規則3" then '▲ 規則3：Gleason score或影像報告不符合條件\n' else '') +
         '\n'
    else '') +

  // 主要規定二：續用條件 - 已提供資料但條件或代碼不符合
  (if Reusable."續用申請" and (("分子檢查報告資料存在" and "PSA檢驗資料存在" and "睪固酮檢驗資料存在") and not "2規則1")
    then '<主要規定二：續用條件>\n' +
         '▲ 規則1：3個月內檢查報告、續用註記、手術去勢或指定藥物終止時間、PSA檢驗、睪固酮檢驗或影像檢查報告不符合續用條件\n' +
         '\n'
    else '') +

  // 主要規定三：藥品使用規則 - 已提供資料但條件或代碼不符合
  (if (("不得併用藥物處方資料存在" and not "3規則1-1")
      or ("V10XX03處方資料存在" and not "3規則2-2")
    )
    then '<主要規定三：藥品使用規則>\n' +
         (if "不得併用藥物處方資料存在" and not "3規則1-1" then '▲ 規則1：合併使用不得併用藥物，且非因嚴重不耐受反應永久停止治療（參考資訊）\n' else '') +
         (if "V10XX03處方資料存在" and not "3規則2-2" then '▲ 規則2：本次申請期間合併使用Radium-223（V10XX03）藥品（參考資訊）\n' else '') +
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
      not "Enzalutamide申請資料存在"
      or not "攝護腺癌ICD診斷資料存在"
      or not "簡要病摘資料存在"
      or not "癌症分期資料存在"
      or not "PSA檢驗資料存在"
      or (not "mCRPC治療藥物處方資料存在" and not "手術去勢處置資料存在")
      or (not "Gleason score資料存在" and not "26029B影像報告資料存在" and not "Radium223無內臟轉移影像報告資料存在")
    )
    then '<主要規定一：初次使用條件>\n' +
         (if not "Enzalutamide申請資料存在" then '▲ 申請醫令：未提供Enzalutamide申請醫令資料\n' else '') +
         (if not "攝護腺癌ICD診斷資料存在" then '▲ 規則1：未提供主要疾病ICD診斷資料\n' else '') +
         (if not "簡要病摘資料存在" then '▲ 規則1：未提供簡要病摘資料\n' else '') +
         (if not "癌症分期資料存在" then '▲ 規則1：未提供癌症分期資料\n' else '') +
         (if not "PSA檢驗資料存在" then '▲ 規則1：未提供PSA檢驗資料\n' else '') +
         (if not "mCRPC治療藥物處方資料存在" and not "手術去勢處置資料存在" then '▲ 規則2：未提供mCRPC治療藥物處方或手術去勢處置資料\n' else '') +
         (if not "Gleason score資料存在" and not "26029B影像報告資料存在" and not "Radium223無內臟轉移影像報告資料存在" then '▲ 規則3：未提供Gleason score或影像報告資料\n' else '') +
         '\n'
    else '') +

  // 主要規定二：續用條件 - 必要資料未填寫
  (if Reusable."續用申請" and (
      not "Enzalutamide申請資料存在"
      or not "分子檢查報告資料存在"
      or not "PSA檢驗資料存在"
      or not "睪固酮檢驗資料存在"
      or not "影像檢查報告資料存在"
    )
    then '<主要規定二：續用條件>\n' +
         (if not "Enzalutamide申請資料存在" then '▲ 申請醫令：未提供Enzalutamide申請醫令資料\n' else '') +
         (if not "分子檢查報告資料存在" then '▲ 規則1：未提供3個月內檢查報告資料\n' else '') +
         (if not "PSA檢驗資料存在" then '▲ 規則1：未提供PSA檢驗資料\n' else '') +
         (if not "睪固酮檢驗資料存在" then '▲ 規則1：未提供睪固酮檢驗資料\n' else '') +
         (if not "影像檢查報告資料存在" then '▲ 規則1：未提供影像檢查報告資料\n' else '') +
         '\n'
    else '') +

  // 主要規定三：藥品使用規則 - 必要資料未填寫
  (if not "療程期間資料存在"
    then '<主要規定三：藥品使用規則>\n' +
         '▲ 規則1/2：未提供療程起迄日期資料（參考資訊）\n' +
         '\n'
    else '')

//============================================
// 審核結果
//============================================

define "攝護腺癌Enzalutamide申請結果_布林":
  case
    when Reusable."初次申請" then "主要規定一"
    when Reusable."續用申請" then "主要規定二"
    else false
  end

define "攝護腺癌Enzalutamide申請結果":
  if Reusable."初次申請" and "攝護腺癌Enzalutamide申請結果_布林"
  then '✓通過：初次使用－攝護腺癌 Enzalutamide 用藥申請'
  else if Reusable."續用申請" and "攝護腺癌Enzalutamide申請結果_布林"
  then '✓通過：續用－攝護腺癌 Enzalutamide 用藥申請'
  else if Reusable."初次申請"
  then '✖不通過：初次使用－攝護腺癌 Enzalutamide 用藥申請'
  else if Reusable."續用申請"
  then '✖不通過：續用－攝護腺癌 Enzalutamide 用藥申請'
  else '✖不通過：無法判定申請類型－攝護腺癌 Enzalutamide 用藥申請'

//============================================
// 審核報告總結
//============================================

define "報告總結":
  '\n=== 攝護腺癌之Enzalutamide 申請審核報告 ===\n' +
  '\n※ 備註：標示為「參考資訊」之檢核項目，係供審核參酌使用，不作為最終【申請結果】判定之依據。\n' +
  '\n【申請類型】' + Reusable."申請類型" + '\n' +
  '\n【●符合項目】\n' +
  (if "符合項目"() = '' then '無\n' else "符合項目"()) +
  '\n【▲不符合項目 - 必要資料未填寫】\n' +
  (if "不符合項目_必要資料未填寫"() = '' then '無\n' else "不符合項目_必要資料未填寫"()) +
  '\n【▲不符合項目 - 條件或代碼不符合】\n' +
  (if "不符合項目_條件或代碼不符合"() = '' then '無\n' else "不符合項目_條件或代碼不符合"()) +
  '\n【申請結果】\n' +
  "攝護腺癌Enzalutamide申請結果" +
  '\n===============================================\n'