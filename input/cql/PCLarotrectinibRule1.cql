//攝護腺癌_Larotrectinib給付規定
library PCLarotrectinibRule1 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

include PCCodeConcept version '1.0.0' called CodeConcept

include PCReusable version '1.0.0' called Reusable

context Patient

//============================================
// 申請紀錄
//============================================

define "本次申請紀錄":
  Reusable."LatestMedicationPlan"(CodeConcept."L01EX12")

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
define "基因檢測":
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
          where ComponentCodeCoding.code in CodeConcept.NTRK
        )
        and ComponentRecord.value is not null
        and ComponentRecord.value is FHIR.string
        and Matches((ComponentRecord.value as FHIR.string).value, '(?i).*(fusion且無後天阻抗性突變).*')
      )
  )

define "1規則1-1":
"基因檢測"
and Reusable."續用註記為1"
and Reusable."醫令類別為1"

//條件2
define "1規則1-2-1":
"ICD-C61"
and (
    (not "3個月內有影像檢查報告" and not "3個月內有檢查報告")
    or ("3個月內有影像檢查報告" and "3個月內有檢查報告")
  )
and "M≠0"

define "簡要病摘":
exists (
    [Claim] C
      where exists (
        C.diagnosis D
          where exists (
            D.type.text T
              where Matches(T.value, '(?i).*說明手術切除會造成嚴重病症.*')
          )
      )
  )

define "1規則1-2-2":
"ICD-C61"
and "簡要病摘"
and "3個月內有影像檢查報告"

define "1規則1-2":
"1規則1-2-1" or "1規則1-2-2"

//條件3
define "1規則1-3":
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

define "1規則1":
"1規則1-1"
and "1規則1-2"
and "1規則1-3"

/*規則2*/
//條件1
define "1規則2":
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
          where ComponentCodeCoding.code in CodeConcept.NTRK
        )
      )
      and exists (
        RasO.derivedFrom Ref
        where Ref.reference is not null
      )
  )

/*規則3*/
//條件1
define "1規則3-1":
"本次申請起始日期" is not null
  and Patient.birthDate is not null
  and AgeInYearsAt(date from "本次申請起始日期") < 18

define "1規則3-2":
Reusable."用藥線別≠1"
and Reusable."續用註記為1"
and Reusable."醫令類別為1"

define "1規則3":
"1規則3-1" and "1規則3-2"

define "主要規定一":
"本次申請紀錄" is not null
and "1規則1" and "1規則2" and "1規則3"

//============================================
// 主要規定二：續用條件
//============================================

/*規則1*/
//條件1
//前次申請紀錄（本次申請之前最近一次的 Larotrectinib 申請）
define "前次申請紀錄":
  Reusable."LatestMedicationPlanBefore"(CodeConcept."L01EX12", "本次申請起始日期")

define "前次申請起始日期":
  Reusable."GetStartTime"("前次申請紀錄")

//影像報告:前次申請後有影像檢查報告（報告時效:前次申請後）
define "前次申請後有影像檢查報告":
  "前次申請紀錄" is not null
  and exists (
    [DiagnosticReport] Report
    where exists (
      Report.code.coding Cdg
      where (
        Cdg in CodeConcept.ICD10PCS2023Image
        or Cdg in CodeConcept.ICD10PCS2014Image
        or Cdg in CodeConcept.NHIMedication
      )
      and Cdg.code in CodeConcept."Radium223MetastasisImageReportCode"
    )
      and Reusable."IsReportAfter"(Report, "前次申請起始日期")
  )

define "2規則1":
"前次申請後有影像檢查報告"
and Reusable."續用註記為2"
and Reusable."醫令類別為1"

define "主要規定二":
"本次申請紀錄" is not null
and "2規則1"

//============================================
// 主要規定三：藥品使用規則
//============================================

/*規則1*/
//條件1
define "每次申請之療程以12週為限":
  "本次申請起始日期" is not null
  and "本次申請終止日期" is not null
  and days between "本次申請起始日期" and "本次申請終止日期" <= 84

define "3規則1":
"每次申請之療程以12週為限"
and Reusable."醫令類別為1"

define "主要規定三":
"本次申請紀錄" is not null
and "3規則1"

//============================================
// 檢核結果用：必要資料存在判斷
//============================================

define "Larotrectinib申請資料存在":
  Reusable."HasMedicationPlanRecord"(CodeConcept."L01EX12")

define "療程期間資料存在":
  Reusable."HasMedicationPlanTiming"(CodeConcept."L01EX12")

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

define "NTRK基因檢測資料存在":
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
              where ComponentCodeCoding.code in CodeConcept.NTRK
          )
      )
  )

define "NTRK基因檢測報告資料存在":
  "1規則2"

define "出生日期資料存在":
  Patient.birthDate is not null

define "前次申請紀錄資料存在":
  "前次申請紀錄" is not null

//============================================
// 列出「符合」項目判斷式
//============================================

define function "符合項目"():
  // 主要規定一：初次使用條件
  (if Reusable."初次申請" and "主要規定一"
    then '<主要規定一：初次使用條件>\n' +
         (if "1規則1" then '● 規則1：符合NTRK基因融合且無後天阻抗性突變檢測、續用註記為1及醫令類別為1，並符合ICD-C61轉移性(M≠0)或手術切除可能造成嚴重病症，及沒有合適替代治療選項之初次使用條件\n' else '') +
         (if "1規則2" then '● 規則2：具NTRK基因檢測報告（檢體來源）資料\n' else '') +
         (if "1規則3" then '● 規則3：符合未滿18歲、用藥線別非第一線、續用註記為1及醫令類別為1之條件\n' else '') +
         '\n'
    else '') +

  // 主要規定二：續用條件
  (if Reusable."續用申請" and "主要規定二"
    then '<主要規定二：續用條件>\n' +
         (if "2規則1" then '● 規則1：前次申請後有影像檢查報告，且續用註記為2、醫令類別為1\n' else '') +
         '\n'
    else '') +

  // 主要規定三：藥品使用規則
  (if "3規則1"
    then '<主要規定三：藥品使用規則>\n' +
         '● 規則1：每次申請之療程以12週為限（參考資訊）\n' +
         '\n'
    else '')

//============================================
// 列出「不符合」項目判斷式 - 條件或代碼不符合
//============================================

define function "不符合項目_條件或代碼不符合"():
  // 主要規定一：初次使用條件 - 已提供資料但條件或代碼不符合
  (if Reusable."初次申請" and (
      (("攝護腺癌ICD診斷資料存在" and "簡要病摘資料存在") and not "1規則1")
      or ("NTRK基因檢測資料存在" and not "1規則2")
      or ("出生日期資料存在" and not "1規則3")
    )
    then '<主要規定一：初次使用條件>\n' +
         (if ("攝護腺癌ICD診斷資料存在" and "簡要病摘資料存在") and not "1規則1" then '▲ 規則1：ICD代碼、癌症分期、影像或檢查報告、簡要病摘或基因檢測結果不符合初次使用條件\n' else '') +
         (if "NTRK基因檢測資料存在" and not "1規則2" then '▲ 規則2：NTRK基因檢測報告（檢體來源連結）資料不符合條件\n' else '') +
         (if "出生日期資料存在" and not "1規則3" then '▲ 規則3：年齡、用藥線別、續用註記或醫令類別不符合條件\n' else '') +
         '\n'
    else '') +

  // 主要規定二：續用條件 - 已提供資料但條件或代碼不符合
  (if Reusable."續用申請" and "影像檢查報告資料存在" and "前次申請紀錄資料存在" and not "2規則1"
    then '<主要規定二：續用條件>\n' +
         '▲ 規則1：影像檢查報告時間、續用註記或醫令類別不符合續用條件\n' +
         '\n'
    else '') +

  // 主要規定三：藥品使用規則 - 已提供資料但條件或代碼不符合
  (if "療程期間資料存在" and not "3規則1"
    then '<主要規定三：藥品使用規則>\n' +
         '▲ 規則1：每次申請之療程超過12週上限，或醫令類別不符合條件（參考資訊）\n' +
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
      not "Larotrectinib申請資料存在"
      or not "攝護腺癌ICD診斷資料存在"
      or not "簡要病摘資料存在"
      or not "癌症分期資料存在"
      or not "NTRK基因檢測資料存在"
      or not "NTRK基因檢測報告資料存在"
      or not "出生日期資料存在"
    )
    then '<主要規定一：初次使用條件>\n' +
         (if not "Larotrectinib申請資料存在" then '▲ 申請醫令：未提供Larotrectinib申請醫令資料\n' else '') +
         (if not "攝護腺癌ICD診斷資料存在" then '▲ 規則1：未提供主要疾病ICD診斷資料\n' else '') +
         (if not "簡要病摘資料存在" then '▲ 規則1：未提供簡要病摘資料\n' else '') +
         (if not "癌症分期資料存在" then '▲ 規則1：未提供癌症分期資料\n' else '') +
         (if not "NTRK基因檢測資料存在" then '▲ 規則1/2：未提供NTRK基因檢測資料\n' else '') +
         (if not "NTRK基因檢測報告資料存在" then '▲ 規則2：未提供NTRK基因檢測報告（檢體來源）資料\n' else '') +
         (if not "出生日期資料存在" then '▲ 規則3：未提供病人出生日期資料，無法判斷年齡\n' else '') +
         '\n'
    else '') +

  // 主要規定二：續用條件 - 必要資料未填寫
  (if Reusable."續用申請" and (
      not "Larotrectinib申請資料存在"
      or not "前次申請紀錄資料存在"
      or not "影像檢查報告資料存在"
    )
    then '<主要規定二：續用條件>\n' +
         (if not "Larotrectinib申請資料存在" then '▲ 申請醫令：未提供Larotrectinib申請醫令資料\n' else '') +
         (if not "前次申請紀錄資料存在" then '▲ 規則1：未提供前次申請紀錄\n' else '') +
         (if not "影像檢查報告資料存在" then '▲ 規則1：未提供影像檢查報告資料\n' else '') +
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

define "攝護腺癌Larotrectinib申請結果_布林":
  case
    when Reusable."初次申請" then "主要規定一"
    when Reusable."續用申請" then "主要規定二"
    else false
  end

define "攝護腺癌Larotrectinib申請結果":
  if Reusable."初次申請" and "攝護腺癌Larotrectinib申請結果_布林"
  then '✓通過：初次使用－攝護腺癌 Larotrectinib 用藥申請'
  else if Reusable."續用申請" and "攝護腺癌Larotrectinib申請結果_布林"
  then '✓通過：續用－攝護腺癌 Larotrectinib 用藥申請'
  else if Reusable."初次申請"
  then '✖不通過：初次使用－攝護腺癌 Larotrectinib 用藥申請'
  else if Reusable."續用申請"
  then '✖不通過：續用－攝護腺癌 Larotrectinib 用藥申請'
  else '✖不通過：無法判定申請類型－攝護腺癌 Larotrectinib 用藥申請'

//============================================
// 審核報告總結
//============================================

define "報告總結":
  '\n=== 攝護腺癌之Larotrectinib 申請審核報告 ===\n' +
  '\n※ 備註：標示為「參考資訊」之檢核項目，係供審核參酌使用，不作為最終【申請結果】判定之依據。\n' +
  '\n【申請類型】' + Reusable."申請類型" + '\n' +
  '\n【●符合項目】\n' +
  (if "符合項目"() = '' then '無\n' else "符合項目"()) +
  '\n【▲不符合項目 - 必要資料未填寫】\n' +
  (if "不符合項目_必要資料未填寫"() = '' then '無\n' else "不符合項目_必要資料未填寫"()) +
  '\n【▲不符合項目 - 條件或代碼不符合】\n' +
  (if "不符合項目_條件或代碼不符合"() = '' then '無\n' else "不符合項目_條件或代碼不符合"()) +
  '\n【申請結果】\n' +
  "攝護腺癌Larotrectinib申請結果" +
  '\n===============================================\n'