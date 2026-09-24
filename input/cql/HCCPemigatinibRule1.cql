//肝癌_Pemigatinib給付規定
library HCCPemigatinibRule1 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

include HCCCodeConcept version '1.0.0' called CodeConcept

include HCCReusable version '1.0.0' called Reusable

context Patient

//============================================
// 申請紀錄
//============================================

// 本次申請紀錄（以最新一筆申請作為本次申請）
define "本次申請紀錄":
  Reusable."LatestMedicationPlan"(CodeConcept.L01EN02)

define "本次申請起始日期":
  Reusable."GetStartTime"("本次申請紀錄")

define "3個月內有影像檢查報告":
  Reusable."HasRecentImageReport"("本次申請起始日期", 90)

define "3個月內有檢查報告":
  Reusable."HasRecentMolecularReport"("本次申請起始日期", 90)

define "癌症分期分數或結果為M≠0":
  Reusable."癌症分期分數或結果為M≠0"

//============================================
// 主要規定一：初次使用條件
//============================================

/*規則1*/
//條件1
define "1規則1-1-1=疾病分類為肝內膽管癌C22.1":
exists (
    [Claim] C
      where exists (
        C.diagnosis D
          where D.sequence = 1
            and exists (
              D.diagnosis.coding Cdg
                where (
                  Cdg in CodeConcept.ICD10CM2023
                  or Cdg in CodeConcept.ICD10CM2014
                )
                and (
                  Substring(Cdg.code, 0, 5) = 'C22.1'
                )
            )
      )
  )

define "1規則1-1=膽管癌疾病分類且符合影像檢查與轉移條件":
"1規則1-1-1=疾病分類為肝內膽管癌C22.1"
and (
    (not "3個月內有影像檢查報告" and not "3個月內有檢查報告")
    or ("3個月內有影像檢查報告" and "3個月內有檢查報告")
  )
and "癌症分期分數或結果為M≠0"
and Reusable."續用註記為1"
and Reusable."醫令類別為1"

//條件2
define "1規則1-2=年齡為18歲以上":
"本次申請起始日期" is not null
  and Patient.birthDate is not null
  and AgeInYearsAt(date from "本次申請起始日期") >= 18

//條件3
define "1規則1-3=FGFR2檢測結果為fusion融合或rearrangement":
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
          where ComponentCodeCoding.code in CodeConcept.FGFR2
        )
        and ComponentRecord.value is not null
        and ComponentRecord.value is FHIR.string
        and Matches((ComponentRecord.value as FHIR.string).value, '(?i).*(fusion|融合|rearrangements|重组).*')
      )
  )

//條件4
define "1規則1-4=用藥線別非第一線且申請註記及醫令類別符合":
Reusable."用藥線別≠1"
and Reusable."續用註記為1"
and Reusable."醫令類別為1"

//條件5
define "1規則1-5=手術不可切除":
exists (
    [Claim] C
      where exists (
        C.diagnosis D
          where exists (
            D.type.text T
              where Matches(T.value, '(?i).*手術不可切除.*')
          )
      )
  )

define "1規則1=成人且符合FGFR2融合或重排之手術不可切除膽管癌":
"1規則1-1=膽管癌疾病分類且符合影像檢查與轉移條件" and "1規則1-2=年齡為18歲以上" and "1規則1-3=FGFR2檢測結果為fusion融合或rearrangement" and "1規則1-4=用藥線別非第一線且申請註記及醫令類別符合" and "1規則1-5=手術不可切除"

/*規則2*/
//條件1
define "1規則2-1=具FGFR2基因檢測資料":
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
          where ComponentCodeCoding.code in CodeConcept.FGFR2
        )
      )
  )

define "1規則2-2=具FGFR2基因檢測報告":
Reusable."HasGenePanelReportForMarker"(CodeConcept.FGFR2)

define "1規則2=具FGFR2基因資料及基因檢測報告":
"1規則2-1=具FGFR2基因檢測資料" and "1規則2-2=具FGFR2基因檢測報告"

//主要規定一
define "主要規定一":
"本次申請紀錄" is not null
and Reusable."初次申請"
and "1規則1=成人且符合FGFR2融合或重排之手術不可切除膽管癌" and "1規則2=具FGFR2基因資料及基因檢測報告"

//============================================
// 主要規定二：續用條件
//============================================

/*規則1*/
//條件1
define "2規則1=影像或檢查資料符合續用條件":
(
  (not "3個月內有影像檢查報告" and not "3個月內有檢查報告")
  or ("3個月內有影像檢查報告" and "3個月內有檢查報告")
)
and Reusable."續用註記為2"
and Reusable."醫令類別為1"

//主要規定二
define "主要規定二":
"本次申請紀錄" is not null
and Reusable."續用申請"
and "2規則1=影像或檢查資料符合續用條件"

//============================================
// 主要規定三：藥品使用規則
//============================================

/*規則1*/
//條件1
define "3規則1=每次申請事前審查之療程以12週為限":
  Reusable."HasMedicationPlanPeriodWithinDays"(CodeConcept.L01EN02, 84)
  and Reusable."醫令類別為1"

define "3規則2=每日劑量以1錠為上限":
Reusable."HasConcurrentDailyDoseAtMost"(CodeConcept.L01EN02, 1, '{tbl}', 'QD')

//主要規定三
define "主要規定三":
"3規則1=每次申請事前審查之療程以12週為限" and "3規則2=每日劑量以1錠為上限"

//============================================
// 檢核結果用：必要資料存在判斷
//============================================

define "Pemigatinib申請資料存在":
  Reusable."HasMedicationPlanRecord"(CodeConcept.L01EN02)

define "療程期間資料存在":
  Reusable."HasMedicationPlanTiming"(CodeConcept.L01EN02)

define "影像報告資料存在":
  Reusable."影像報告資料存在"

define "分子病理報告資料存在":
  Reusable."分子病理報告資料存在"

define "影像或檢查報告資料存在":
  Reusable."影像或檢查報告資料存在"

define "癌症分期資料存在":
  Reusable."癌症分期資料存在"

define "FGFR2檢測資料存在":
  "1規則2-1=具FGFR2基因檢測資料"

define "FGFR2基因報告資料存在":
  "1規則2-2=具FGFR2基因檢測報告"

define "手術不可切除資料存在":
  Reusable."HasClaimDiagnosisText"('(?i).*手術不可切除.*')

define "劑量資料存在":
  exists (
    [MedicationRequest] MR
    where Reusable."IsMedicationPlan"(MR, CodeConcept.L01EN02)
      and exists (
        MR.dosageInstruction DI
        where exists (
          DI.timing.code.coding C
          where C.code = 'QD'
        )
        and exists (
          DI.doseAndRate DR
          where (DR.dose as FHIR.SimpleQuantity) is not null
            and (DR.dose as FHIR.SimpleQuantity).code = '{tbl}'
        )
      )
  )

//============================================
// 列出「符合」項目判斷式
//============================================

define function "符合項目"():
  (if Reusable."初次申請" and ("1規則1-1=膽管癌疾病分類且符合影像檢查與轉移條件" or "1規則1-2=年齡為18歲以上" or "1規則1-3=FGFR2檢測結果為fusion融合或rearrangement" or "1規則1-4=用藥線別非第一線且申請註記及醫令類別符合" or "1規則1-5=手術不可切除" or "1規則2=具FGFR2基因資料及基因檢測報告")
    then '<主要規定一：初次使用條件>\n' +
      (if "1規則1-1=膽管癌疾病分類且符合影像檢查與轉移條件" then '● 規則1-1：符合膽管癌疾病分類、影像/檢查與轉移條件\n' else '') +
      (if "1規則1-2=年齡為18歲以上" then '● 規則1-2：年齡符合18歲以上\n' else '') +
      (if "1規則1-3=FGFR2檢測結果為fusion融合或rearrangement" then '● 規則1-3：FGFR2檢測結果符合fusion、融合或rearrangement條件\n' else '') +
      (if "1規則1-4=用藥線別非第一線且申請註記及醫令類別符合" then '● 規則1-4：用藥線別、申請註記及醫令類別符合條件\n' else '') +
      (if "1規則1-5=手術不可切除" then '● 規則1-5：符合手術不可切除條件\n' else '') +
      (if "1規則2=具FGFR2基因資料及基因檢測報告" then '● 規則2：具FGFR2基因資料及基因檢測報告\n' else '') +
      '\n'
    else '') +
  (if Reusable."續用申請" and "主要規定二"
    then '<主要規定二：續用條件>\n● 續用規則1：影像/檢查資料、申請註記及醫令類別符合續用條件\n\n'
    else '') +
  (if ("3規則1=每次申請事前審查之療程以12週為限" or "3規則2=每日劑量以1錠為上限")
    then '<主要規定三：藥品使用規則>\n' +
      (if "3規則1=每次申請事前審查之療程以12週為限" then '● 規則3-1：每次申請事前審查之療程以12週為限（參考資訊）\n' else '') +
      (if "3規則2=每日劑量以1錠為上限" then '● 規則3-2：每日劑量符合1錠上限\n' else '') +
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
      not "Pemigatinib申請資料存在"
      or not Reusable."主要疾病ICD診斷資料存在"
      or not "癌症分期資料存在"
      or not "FGFR2檢測資料存在"
      or not "FGFR2基因報告資料存在"
      or not "手術不可切除資料存在"
    )
    then '<主要規定一：初次使用條件>\n' +
      (if not "Pemigatinib申請資料存在" then '▲ 申請醫令：未提供Pemigatinib申請醫令資料\n' else '') +
      (if not Reusable."主要疾病ICD診斷資料存在" then '▲ 規則1-1：未提供主要疾病ICD診斷資料\n' else '') +
      (if not "癌症分期資料存在" then '▲ 規則1-1：未提供癌症分期資料\n' else '') +
      (if not "FGFR2檢測資料存在" then '▲ 規則1-3：未提供FGFR2檢測資料\n' else '') +
      (if not "FGFR2基因報告資料存在" then '▲ 規則2：未提供FGFR2基因檢測報告\n' else '') +
      (if not "手術不可切除資料存在" then '▲ 規則1-5：未提供手術不可切除相關說明\n' else '') +
      '\n'
    else '') +
  (if Reusable."續用申請" and not "Pemigatinib申請資料存在"
    then '<主要規定二：續用條件>\n▲ 申請醫令：未提供Pemigatinib申請醫令資料\n\n'
    else '') +
  (if (not "療程期間資料存在" or not "劑量資料存在")
    then '<主要規定三：藥品使用規則>\n' +
      (if not "療程期間資料存在" then '▲ 規則3-1：未提供療程起迄日期資料（參考資訊）\n' else '') +
      (if not "劑量資料存在" then '▲ 規則3-2：未提供每日劑量資料\n' else '') +
      '\n'
    else '')

//============================================
// 列出「不符合」項目判斷式 - 條件或代碼不符合
//============================================

define function "不符合項目_條件或代碼不符合"():
  (if Reusable."初次申請" and (
      ((Reusable."主要疾病ICD診斷資料存在" or "癌症分期資料存在" or "影像或檢查報告資料存在") and not "1規則1-1=膽管癌疾病分類且符合影像檢查與轉移條件")
      or not "1規則1-2=年齡為18歲以上"
      or ("FGFR2檢測資料存在" and not "1規則1-3=FGFR2檢測結果為fusion融合或rearrangement")
      or not "1規則1-4=用藥線別非第一線且申請註記及醫令類別符合"
      or ("手術不可切除資料存在" and not "1規則1-5=手術不可切除")
      or (("FGFR2檢測資料存在" or "FGFR2基因報告資料存在") and not "1規則2=具FGFR2基因資料及基因檢測報告")
    )
    then '<主要規定一：初次使用條件>\n' +
      (if (Reusable."主要疾病ICD診斷資料存在" or "癌症分期資料存在" or "影像或檢查報告資料存在") and not "1規則1-1=膽管癌疾病分類且符合影像檢查與轉移條件" then '▲ 規則1-1：疾病分類、影像/檢查、轉移狀態、申請註記或醫令類別不符合條件\n' else '') +
      (if not "1規則1-2=年齡為18歲以上" then '▲ 規則1-2：年齡未滿18歲或生日/申請日期不符合判定條件\n' else '') +
      (if "FGFR2檢測資料存在" and not "1規則1-3=FGFR2檢測結果為fusion融合或rearrangement" then '▲ 規則1-3：FGFR2檢測結果不符合fusion、融合或rearrangement條件\n' else '') +
      (if not "1規則1-4=用藥線別非第一線且申請註記及醫令類別符合" then '▲ 規則1-4：用藥線別、申請註記或醫令類別不符合條件\n' else '') +
      (if "手術不可切除資料存在" and not "1規則1-5=手術不可切除" then '▲ 規則1-5：手術不可切除相關說明不符合條件\n' else '') +
      (if ("FGFR2檢測資料存在" or "FGFR2基因報告資料存在") and not "1規則2=具FGFR2基因資料及基因檢測報告" then '▲ 規則2：FGFR2基因資料或基因報告不符合條件\n' else '') +
      '\n'
    else '') +
  (if Reusable."續用申請" and "Pemigatinib申請資料存在" and not "主要規定二"
    then '<主要規定二：續用條件>\n▲ 續用規則1：影像/檢查資料、申請註記或醫令類別不符合續用條件\n\n'
    else '') +
  (if (("療程期間資料存在" and not "3規則1=每次申請事前審查之療程以12週為限") or ("劑量資料存在" and not "3規則2=每日劑量以1錠為上限"))
    then '<主要規定三：藥品使用規則>\n' +
      (if "療程期間資料存在" and not "3規則1=每次申請事前審查之療程以12週為限" then '▲ 規則3-1：每次申請事前審查之療程超過12週上限（參考資訊）\n' else '') +
      (if "劑量資料存在" and not "3規則2=每日劑量以1錠為上限" then '▲ 規則3-2：每日劑量超過1錠上限\n' else '') +
      '\n'
    else '')

//============================================
// 審核結果
//============================================

define "肝癌Pemigatinib申請結果_布林":
  case
    when Reusable."初次申請" then "主要規定一" and "3規則2=每日劑量以1錠為上限"
    when Reusable."續用申請" then "主要規定二" and "3規則2=每日劑量以1錠為上限"
    else false
  end

define "肝癌Pemigatinib申請結果":
  if Reusable."初次申請" and "肝癌Pemigatinib申請結果_布林"
  then '✓通過：初次使用－肝癌 Pemigatinib 用藥申請'
  else if Reusable."續用申請" and "肝癌Pemigatinib申請結果_布林"
  then '✓通過：續用－肝癌 Pemigatinib 用藥申請'
  else if Reusable."初次申請"
  then '✖不通過：初次使用－肝癌 Pemigatinib 用藥申請'
  else if Reusable."續用申請"
  then '✖不通過：續用－肝癌 Pemigatinib 用藥申請'
  else '✖不通過：無法判定申請類型－肝癌 Pemigatinib 用藥申請'

//============================================
// 審核報告總結
//============================================

define "報告總結":
  '\n=== 肝癌 Pemigatinib 申請審核報告 ===\n' +
  '\n※ 備註：標示為「參考資訊」之檢核項目，係供審核參酌使用，不作為最終【申請結果】判定之依據。\n' +
  '\n【申請類型】' + Reusable."申請類型" + '\n' +
  '\n【●符合項目】\n' +
  (if "符合項目"() = '' then '無\n' else "符合項目"()) +
  '\n【▲不符合項目 - 必要資料未填寫】\n' +
  (if "不符合項目_必要資料未填寫"() = '' then '無\n' else "不符合項目_必要資料未填寫"()) +
  '\n【▲不符合項目 - 條件或代碼不符合】\n' +
  (if "不符合項目_條件或代碼不符合"() = '' then '無\n' else "不符合項目_條件或代碼不符合"()) +
  '\n【申請結果】\n' +
  "肝癌Pemigatinib申請結果" +
  '\n===============================================\n'
