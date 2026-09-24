//肝癌_Larotrectinib給付規定
library HCCLarotrectinibRule1 version '1.0.0'

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
  Reusable."LatestMedicationPlan"(CodeConcept.L01EX12)

define "本次申請起始日期":
  Reusable."GetStartTime"("本次申請紀錄")

define "首次申請紀錄":
  First(
    [MedicationRequest] MR
      where Reusable."IsMedicationPlan"(MR, CodeConcept.L01EX12)
      sort by FHIRHelpers.ToDateTime((dosageInstruction[0].timing.repeat.bounds as Period).start)
  )

define "首次申請起始日期":
  Reusable."GetStartTime"("首次申請紀錄")

// 前次申請紀錄（本次申請之前最近一次的申請）
define "前次申請紀錄":
  Reusable."LatestMedicationPlanBefore"(CodeConcept.L01EX12, "本次申請起始日期")

define "前次申請起始日期":
  Reusable."GetStartTime"("前次申請紀錄")

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
define "NTRK基因融合且無後天阻抗性突變檢測資料":
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
          where ComponentCodeCoding.code in CodeConcept.LarotrectinibGeneTest
        )
        and ComponentRecord.value is not null
        and ComponentRecord.value is FHIR.string
        and Matches((ComponentRecord.value as FHIR.string).value, '(?i).*fusion且無後天阻抗性突變.*')
      )
  )

define "1規則1-1=NTRK 基因融合且無已知的後天阻抗性突變":
"NTRK基因融合且無後天阻抗性突變檢測資料"
and Reusable."續用註記為1"
and Reusable."醫令類別為1"

//條件2
define "1規則1-2-1=轉移性實體腫瘤":
  Reusable."ICD-10使用C22C23C24"
  and "癌症分期分數或結果為M≠0"
  and (
    (not "3個月內有影像檢查報告" and not "3個月內有檢查報告")
    or ("3個月內有影像檢查報告" and "3個月內有檢查報告")
  )

define "1規則1-2-2=手術切除極可能造成嚴重病症":
Reusable."ICD-10使用C22C23C24"
and exists (
    [Claim] C
      where exists (
        C.diagnosis D
          where exists (
            D.type.text T
              where Matches(T.value, '(?i).*手術切除會造成嚴重病症.*')
          )
      )
  )
and "3個月內有影像檢查報告"

define "1規則1-2=轉移性實體腫瘤或手術切除極可能造成嚴重病症":
"1規則1-2-1=轉移性實體腫瘤"
or "1規則1-2-2=手術切除極可能造成嚴重病症"

//條件3
define "1規則1-3=沒有合適的替代治療選項":
exists (
    [Claim] C
      where exists (
        C.diagnosis D
          where exists (
            D.type.text T
              where Matches(T.value, '(?i).*沒有合適的替代治療選項.*')
          )
      )
  )

define "1規則1=符合NTRK基因融合之實體腫瘤條件":
"1規則1-1=NTRK 基因融合且無已知的後天阻抗性突變"
and "1規則1-2=轉移性實體腫瘤或手術切除極可能造成嚴重病症"
and "1規則1-3=沒有合適的替代治療選項"

/*規則2*/
define "1規則2-1=具NTRK基因檢測資料":
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
          where ComponentCodeCoding.code in CodeConcept.LarotrectinibGeneTest
        )
      )
  )

define "1規則2-2=具NTRK基因檢測報告":
Reusable."HasGenePanelReportForMarker"(CodeConcept.LarotrectinibGeneTest)

define "1規則2=具NTRK基因資料及基因檢測報告":
"1規則2-1=具NTRK基因檢測資料" and "1規則2-2=具NTRK基因檢測報告"

/*規則3*/
//條件1
define "1規則3-1=未滿18歲":
"本次申請起始日期" is not null
  and Patient.birthDate is not null
  and AgeInYearsAt(date from "本次申請起始日期") < 18

//條件2
define "1規則3-2=未滿18歲者用藥線別非第一線且申請註記及醫令類別符合":
Reusable."用藥線別≠1"
and Reusable."續用註記為1"
and Reusable."醫令類別為1"

//條件3
define "1規則3-3-1=膽道癌疾病分類且申請註記及醫令類別符合":
Reusable."ICD-10使用C22.1C23C24"
and Reusable."續用註記為1"
and Reusable."醫令類別為1"

define "1規則3-3-2-1=無法手術切除":
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

define "1規則3-3-2-2=晚期或復發":
"癌症分期分數或結果為M≠0"

define "1規則3-3-2=無法手術切除或晚期或復發":
"1規則3-3-2-1=無法手術切除" or "1規則3-3-2-2=晚期或復發"

define "1規則3-3-3=用藥線別非第一線且申請註記及醫令類別符合":
Reusable."用藥線別≠1"
and Reusable."續用註記為1"
and Reusable."醫令類別為1"

define "1規則3-3=18歲以上膽道癌條件":
"1規則3-3-1=膽道癌疾病分類且申請註記及醫令類別符合" and "1規則3-3-2=無法手術切除或晚期或復發" and "1規則3-3-3=用藥線別非第一線且申請註記及醫令類別符合"

define "1規則3=依年齡符合對應疾病別及用藥線別條件":
if "1規則3-1=未滿18歲" then "1規則3-2=未滿18歲者用藥線別非第一線且申請註記及醫令類別符合" else "1規則3-3=18歲以上膽道癌條件"

//主要規定一
define "主要規定一":
"本次申請紀錄" is not null
and Reusable."初次申請"
and "1規則1=符合NTRK基因融合之實體腫瘤條件" and "1規則2=具NTRK基因資料及基因檢測報告" and "1規則3=依年齡符合對應疾病別及用藥線別條件"

//============================================
// 主要規定二：續用條件
//============================================

/*規則1*/
//條件1
define "2規則1=本次與前次申請間有影像檢查報告":
exists (
    [DiagnosticReport] CurrentReport
    where exists (
      CurrentReport.code.coding CurrentCdg
      where (
        CurrentCdg in CodeConcept.ICD10PCS2023Image
        or CurrentCdg in CodeConcept.ICD10PCS2014Image
      )
      and CurrentCdg.code in CodeConcept.ImageCodes
    )
    and CurrentReport.effective is not null
    and FHIRHelpers.ToDateTime(CurrentReport.effective) >= "前次申請起始日期"
    and FHIRHelpers.ToDateTime(CurrentReport.effective) <= "本次申請起始日期"
    )
and Reusable."續用註記為2"
and Reusable."醫令類別為1"

//主要規定二
define "主要規定二":
"本次申請紀錄" is not null
and Reusable."續用申請"
and "2規則1=本次與前次申請間有影像檢查報告"

//============================================
// 主要規定三：藥品使用規則
//============================================

/*規則1*/
//條件1
define "3規則1=每次申請事前審查之療程以12週為限":
  Reusable."HasMedicationPlanPeriodWithinDays"(CodeConcept.L01EX12, 84)
  and Reusable."醫令類別為1"

//主要規定三
define "主要規定三":
"3規則1=每次申請事前審查之療程以12週為限"

//============================================
// 檢核結果用：必要資料存在判斷
//============================================

define "Larotrectinib申請資料存在":
  Reusable."HasMedicationPlanRecord"(CodeConcept.L01EX12)

define "療程期間資料存在":
  Reusable."HasMedicationPlanTiming"(CodeConcept.L01EX12)

define "影像報告資料存在":
  Reusable."影像報告資料存在"

define "分子病理報告資料存在":
  Reusable."分子病理報告資料存在"

define "影像或檢查報告資料存在":
  Reusable."影像或檢查報告資料存在"

define "癌症分期資料存在":
  Reusable."癌症分期資料存在"

define "NTRK檢測資料存在":
  "1規則2-1=具NTRK基因檢測資料"

define "NTRK基因報告資料存在":
  "1規則2-2=具NTRK基因檢測報告"

define "替代治療說明資料存在":
  Reusable."HasClaimDiagnosisText"('(?i).*沒有合適的替代治療選項.*')

define "手術風險或不可切除資料存在":
  Reusable."HasClaimDiagnosisText"('(?i).*(手術切除會造成嚴重病症|無法手術切除).*')

//============================================
// 列出「符合」項目判斷式
//============================================

define function "符合項目"():
  (if Reusable."初次申請" and (
      "1規則1-1=NTRK 基因融合且無已知的後天阻抗性突變"
      or "1規則1-2=轉移性實體腫瘤或手術切除極可能造成嚴重病症"
      or "1規則1-3=沒有合適的替代治療選項"
      or "1規則2=具NTRK基因資料及基因檢測報告"
      or "1規則3=依年齡符合對應疾病別及用藥線別條件"
    )
    then '<主要規定一：初次使用條件>\n' +
      (if "1規則1-1=NTRK 基因融合且無已知的後天阻抗性突變" then '● 規則1-1：NTRK基因融合且無已知後天阻抗性突變\n' else '') +
      (if "1規則1-2=轉移性實體腫瘤或手術切除極可能造成嚴重病症" then '● 規則1-2：符合轉移性實體腫瘤或手術切除可能造成嚴重病症條件\n' else '') +
      (if "1規則1-3=沒有合適的替代治療選項" then '● 規則1-3：沒有合適的替代治療選項\n' else '') +
      (if "1規則2=具NTRK基因資料及基因檢測報告" then '● 規則2：具NTRK基因資料及基因檢測報告\n' else '') +
      (if "1規則3=依年齡符合對應疾病別及用藥線別條件" then '● 規則3：符合年齡、疾病別、用藥線別、申請註記及醫令類別條件\n' else '') +
      '\n'
    else '') +
  (if Reusable."續用申請" and "主要規定二"
    then '<主要規定二：續用條件>\n● 續用規則1：本次與前次申請間有影像檢查報告，且申請註記與醫令類別符合條件\n\n'
    else '') +
  (if "3規則1=每次申請事前審查之療程以12週為限"
    then '<主要規定三：藥品使用規則>\n● 規則3-1：每次申請事前審查之療程以12週為限（參考資訊）\n\n'
    else '')

//============================================
// 列出「不符合」項目判斷式 - 必要資料未填寫
//============================================

define function "不符合項目_必要資料未填寫"():
  (if Reusable."申請類型未知"
    then '▲ 申請類型：未提供可判定初次使用或續用之申請註記\n\n'
    else '') +
  (if Reusable."初次申請" and (
      not "Larotrectinib申請資料存在"
      or not "NTRK檢測資料存在"
      or not "NTRK基因報告資料存在"
      or not Reusable."主要疾病ICD診斷資料存在"
      or not "替代治療說明資料存在"
    )
    then '<主要規定一：初次使用條件>\n' +
      (if not "Larotrectinib申請資料存在" then '▲ 申請醫令：未提供Larotrectinib申請醫令資料\n' else '') +
      (if not "NTRK檢測資料存在" then '▲ 規則1-1：未提供NTRK檢測資料\n' else '') +
      (if not "NTRK基因報告資料存在" then '▲ 規則2：未提供NTRK基因檢測報告\n' else '') +
      (if not Reusable."主要疾病ICD診斷資料存在" then '▲ 規則1-2/1-3：未提供主要疾病ICD診斷資料\n' else '') +
      (if not "替代治療說明資料存在" then '▲ 規則1-3：未提供沒有合適替代治療選項之說明\n' else '') +
      '\n'
    else '') +
  (if Reusable."續用申請" and (
      not "Larotrectinib申請資料存在"
      or not "影像報告資料存在"
      or "前次申請紀錄" is null
    )
    then '<主要規定二：續用條件>\n' +
      (if not "Larotrectinib申請資料存在" then '▲ 申請醫令：未提供Larotrectinib申請醫令資料\n' else '') +
      (if "前次申請紀錄" is null then '▲ 續用規則1：未提供前次申請紀錄\n' else '') +
      (if not "影像報告資料存在" then '▲ 續用規則1：未提供本次與前次申請間之影像檢查報告\n' else '') +
      '\n'
    else '') +
  (if not "療程期間資料存在"
    then '<主要規定三：藥品使用規則>\n▲ 規則3-1：未提供療程起迄日期資料（參考資訊）\n\n'
    else '')

//============================================
// 列出「不符合」項目判斷式 - 條件或代碼不符合
//============================================

define function "不符合項目_條件或代碼不符合"():
  (if Reusable."初次申請" and (
      ("NTRK檢測資料存在" and not "1規則1-1=NTRK 基因融合且無已知的後天阻抗性突變")
      or ((Reusable."主要疾病ICD診斷資料存在" or "癌症分期資料存在" or "影像或檢查報告資料存在" or "手術風險或不可切除資料存在") and not "1規則1-2=轉移性實體腫瘤或手術切除極可能造成嚴重病症")
      or ("替代治療說明資料存在" and not "1規則1-3=沒有合適的替代治療選項")
      or (("NTRK檢測資料存在" or "NTRK基因報告資料存在") and not "1規則2=具NTRK基因資料及基因檢測報告")
      or not "1規則3=依年齡符合對應疾病別及用藥線別條件"
    )
    then '<主要規定一：初次使用條件>\n' +
      (if "NTRK檢測資料存在" and not "1規則1-1=NTRK 基因融合且無已知的後天阻抗性突變" then '▲ 規則1-1：NTRK檢測結果不符合基因融合且無已知後天阻抗性突變條件\n' else '') +
      (if (Reusable."主要疾病ICD診斷資料存在" or "癌症分期資料存在" or "影像或檢查報告資料存在" or "手術風險或不可切除資料存在") and not "1規則1-2=轉移性實體腫瘤或手術切除極可能造成嚴重病症" then '▲ 規則1-2：疾病別、分期、影像/檢查或手術風險資料不符合條件\n' else '') +
      (if "替代治療說明資料存在" and not "1規則1-3=沒有合適的替代治療選項" then '▲ 規則1-3：替代治療選項說明不符合條件\n' else '') +
      (if ("NTRK檢測資料存在" or "NTRK基因報告資料存在") and not "1規則2=具NTRK基因資料及基因檢測報告" then '▲ 規則2：NTRK基因資料或基因報告不符合條件\n' else '') +
      (if not "1規則3=依年齡符合對應疾病別及用藥線別條件" then '▲ 規則3：年齡、疾病別、用藥線別、申請註記或醫令類別不符合條件\n' else '') +
      '\n'
    else '') +
  (if Reusable."續用申請" and "影像報告資料存在" and "前次申請紀錄" is not null and not "主要規定二"
    then '<主要規定二：續用條件>\n▲ 續用規則1：影像檢查報告時間區間、申請註記或醫令類別不符合續用條件\n\n'
    else '') +
  (if "療程期間資料存在" and not "3規則1=每次申請事前審查之療程以12週為限"
    then '<主要規定三：藥品使用規則>\n▲ 規則3-1：每次申請事前審查之療程超過12週上限（參考資訊）\n\n'
    else '')

//============================================
// 審核結果
//============================================

define "肝癌Larotrectinib申請結果_布林":
  case
    when Reusable."初次申請" then "主要規定一"
    when Reusable."續用申請" then "主要規定二"
    else false
  end

define "肝癌Larotrectinib申請結果":
  if Reusable."初次申請" and "肝癌Larotrectinib申請結果_布林"
  then '✓通過：初次使用－肝癌 Larotrectinib 用藥申請'
  else if Reusable."續用申請" and "肝癌Larotrectinib申請結果_布林"
  then '✓通過：續用－肝癌 Larotrectinib 用藥申請'
  else if Reusable."初次申請"
  then '✖不通過：初次使用－肝癌 Larotrectinib 用藥申請'
  else if Reusable."續用申請"
  then '✖不通過：續用－肝癌 Larotrectinib 用藥申請'
  else '✖不通過：無法判定申請類型－肝癌 Larotrectinib 用藥申請'

//============================================
// 審核報告總結
//============================================

define "報告總結":
  '\n=== 肝癌 Larotrectinib 申請審核報告 ===\n' +
  '\n※ 備註：標示為「參考資訊」之檢核項目，係供審核參酌使用，不作為最終【申請結果】判定之依據。\n' +
  '\n【申請類型】' + Reusable."申請類型" + '\n' +
  '\n【●符合項目】\n' +
  (if "符合項目"() = '' then '無\n' else "符合項目"()) +
  '\n【▲不符合項目 - 必要資料未填寫】\n' +
  (if "不符合項目_必要資料未填寫"() = '' then '無\n' else "不符合項目_必要資料未填寫"()) +
  '\n【▲不符合項目 - 條件或代碼不符合】\n' +
  (if "不符合項目_條件或代碼不符合"() = '' then '無\n' else "不符合項目_條件或代碼不符合"()) +
  '\n【申請結果】\n' +
  "肝癌Larotrectinib申請結果" +
  '\n===============================================\n'
