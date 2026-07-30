//肺癌_Tepotinib給付規定
library LCTepotinibRule1 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

include LCCodeConcept version '1.0.0' called CodeConcept

include LCReusable version '1.0.0' called Reusable

context Patient

//============================================
// 申請紀錄
//============================================

define "本次申請紀錄":
  Reusable."LatestMedicationPlan"(CodeConcept.L01EX21)

define "本次申請起始日期":
  Reusable."GetStartTime"("本次申請紀錄")

define "3個月內有影像檢查報告":
  Reusable."HasRecentImageReport"("本次申請起始日期", 90)

define "3個月內有檢查報告":
  Reusable."HasRecentMolecularReport"("本次申請起始日期", 90)

define "3個月內有檢查報告(部分1)":
  Reusable."HasRecentMolecularReport1"("本次申請起始日期", 90)

define "3個月內有檢查報告(部分2)":
  Reusable."HasRecentMolecularReport2"("本次申請起始日期", 90)

define "癌症分期分數或結果為M≠0":
  Reusable."癌症分期分數或結果為M≠0"



//============================================
// 主要規定一：初次使用條件
//============================================

/*1-1規則1*/
define "1-1規則1-1=適用於治療轉移性非小細胞肺癌的成人病人":
"本次申請起始日期" is not null
  and Patient.birthDate is not null
  and Reusable."IsPatientAdultAt"(date from "本次申請起始日期")
  and Reusable."ICD-10使用C34"
  and Reusable."HasClaimDiagnosisText"('(?i).*(non-small cell  carcinoma|非小細胞肺癌).*')
  and (
    (not "3個月內有影像檢查報告" and not "3個月內有檢查報告")
    or ("3個月內有影像檢查報告" and "3個月內有檢查報告")
  )
  and "癌症分期分數或結果為M≠0"
  and Reusable."HasReportResultString"('(?i).*(non-small cell  carcinoma|非小細胞肺癌).*')
  and Reusable."續用註記為1"
  and Reusable."醫令類別為1"

define "1-1規則1-2=其腫瘤帶有導致間質上皮轉化因子外顯子14跳讀式突變":
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
          where ComponentCodeCoding.code in CodeConcept.MET
        )
      )
      and RasO.value is not null
      and RasO.value is FHIR.string
      and Matches((RasO.value as FHIR.string).value, '(?i).*MET exon 14 skipping mutation.*')
  )

define "主要規定1-1":
"1-1規則1-1=適用於治療轉移性非小細胞肺癌的成人病人"
and "1-1規則1-2=其腫瘤帶有導致間質上皮轉化因子外顯子14跳讀式突變"

/*1-2規則1*/
define "1-2規則1-1=初次申請時需檢具確實患有非小細胞肺癌之病理報告":
"3個月內有檢查報告(部分1)"
and exists (
    [DiagnosticReport] DR
      where exists (
          DR.presentedForm P
            where P.url is not null
        )
    )

define "1-2規則1-2=初次申請時需檢具確實患有非小細胞肺癌之細胞檢查報告":
"3個月內有檢查報告(部分2)"
and exists (
    [DiagnosticReport] DR
        where exists (
          DR.presentedForm P
            where P.url is not null
        )
    )

define "1-2規則1":
"1-2規則1-1=初次申請時需檢具確實患有非小細胞肺癌之病理報告"
or "1-2規則1-2=初次申請時需檢具確實患有非小細胞肺癌之細胞檢查報告"

/*1-2規則2*/
define "1-2規則2":
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
          where ComponentCodeCoding.code in CodeConcept.MET
        )
      )
      and RasO.method.coding.code is not null
      and exists (
      [Organization] O
        where exists (
          O.identifier I
            where I.value is not null
        )
    )
      and exists (
      [DiagnosticReport] DR
        where exists (
          DR.presentedForm P
            where P.url is not null
        )
    )
  )

define "主要規定1-2":
"1-2規則1"
and "1-2規則2"

define "主要規定一":
"本次申請紀錄" is not null
and "主要規定1-1"
and "主要規定1-2"

//============================================
// 主要規定二：續用條件
//============================================

define "2規則1":
"3個月內有影像檢查報告"
and Reusable."續用註記為2"
and Reusable."醫令類別為1"

define "主要規定二":
"本次申請紀錄" is not null
and "2規則1"

//============================================
// 主要規定三：藥品使用規則
//============================================

define "3規則1=每次申請事前審查之療程以3個月為限":
Reusable."HasMedicationPlanPeriodWithinDays"(CodeConcept.L01EX21, 84)

define "3規則2=每日最多處方2粒":
Reusable."HasConcurrentDailyDoseAtMost"(CodeConcept.L01EX21, 2, '{tbl}', 'QD')

define "主要規定三":
"3規則1=每次申請事前審查之療程以3個月為限"
and "3規則2=每日最多處方2粒"

define "主要規定三_核心條件":
  "3規則2=每日最多處方2粒"

//============================================
// 檢核結果用：必要資料存在判斷
//============================================

define "主要疾病ICD資料存在":
  exists (
    [Claim] C
      where exists (
        C.diagnosis D
          where D.sequence = 1
            and exists (
              D.diagnosis.coding Cdg
                where Cdg in CodeConcept.ICD10CM2023
                  or Cdg in CodeConcept.ICD10CM2014
            )
      )
  )

define "主要疾病文字資料存在":
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

define "報告結論資料存在":
  exists (
    [DiagnosticReport] DR
      where DR.conclusion is not null
  )

define "影像或檢查報告資料存在":
  exists (
    [DiagnosticReport] Report
      where Report.effective is not null
        and exists (
          Report.code.coding Cdg
            where Cdg in CodeConcept.ICD10PCS2023Image
              or Cdg in CodeConcept.ICD10PCS2014Image
              or Cdg in CodeConcept.LOINC
        )
  )

define "癌症分期資料存在":
  exists (
    [Observation] O
      where exists (
        O.code.coding Cdg
          where Cdg.code = '399390009'
            and Cdg in CodeConcept.SNOMED
      )
      and O.value is not null
  )

define "生日資料存在":
  Patient.birthDate is not null

define "病患生日資料存在":
  "生日資料存在"

define "MET基因檢測資料存在":
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
                where ComponentCodeCoding.code in CodeConcept.MET
            )
            and ComponentRecord.value is not null
        )
  )

define "病理或細胞檢查報告資料存在":
  exists (
    [DiagnosticReport] DR
      where exists (
        DR.code.coding Cdg
          where Cdg in CodeConcept.LOINC
            and (
              Cdg.code in CodeConcept.MolecularReport1
              or Cdg.code in CodeConcept.MolecularReport2
            )
      )
      and exists (
        DR.presentedForm P
          where P.url is not null
      )
  )

define "1-2規則1=病理或細胞檢查報告資料存在":
  "病理或細胞檢查報告資料存在"

define "1-2規則2=基因檢測方法及採檢機構資料存在":
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
                where ComponentCodeCoding.code in CodeConcept.MET
            )
        )
        and RasO.method.coding.code is not null
  )
  and exists (
    [Organization] O
      where exists (
        O.identifier I
          where I.value is not null
      )
  )
  and exists (
    [DiagnosticReport] DR
      where exists (
        DR.presentedForm P
          where P.url is not null
      )
  )

define "續用註記資料存在":
  exists (
    [Claim] C
      where exists (
        C.item I
          where exists (
            I.modifier M
              where exists (
                M.coding Cdg
                  where Cdg in CodeConcept.NHIContinuationStatus
              )
          )
      )
  )

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
  exists (
    [MedicationRequest] MR
      where Reusable."IsMedicationPlan"(MR, CodeConcept.L01EX21)
  )

define "3規則2=每日劑量資料存在":
  exists (
    [MedicationRequest] MR
      where Reusable."IsMedicationPlan"(MR, CodeConcept.L01EX21)
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
// 列出檢核項目
define "必要資料皆存在":
  not (
    (
      Reusable."初次申請" and (
          "本次申請紀錄" is null
          or not "主要疾病ICD資料存在"
          or not "病患生日資料存在"
          or not "主要疾病文字資料存在"
          or not "報告結論資料存在"
          or not "影像或檢查報告資料存在"
          or not "癌症分期資料存在"
          or not "續用註記資料存在"
          or not "醫令類別資料存在"
          or not "MET基因檢測資料存在"
          or not "1-2規則1=病理或細胞檢查報告資料存在"
          or not "1-2規則2=基因檢測方法及採檢機構資料存在"
        )
    )
    or (
      Reusable."續用申請" and (
          "本次申請紀錄" is null
          or not "影像或檢查報告資料存在"
          or not "續用註記資料存在"
          or not "醫令類別資料存在"
        )
    )
    or (
      (
          "本次申請紀錄" is null
          or not "療程期間資料存在"
          or not "3規則2=每日劑量資料存在"
        )
    )
  )


//============================================

define function "符合項目"():
  (if Reusable."初次申請" and "主要規定一"
    then '<主要規定一：初次使用條件>\n' +
         '● 主要規定1-1：適用於治療轉移性非小細胞肺癌且腫瘤帶有MET外顯子14跳讀式突變之成人病人\n' +
         '  ● 1-1規則1-1：適用於治療轉移性非小細胞肺癌的成人病人\n' +
         '  ● 1-1規則1-2：其腫瘤帶有導致間質上皮轉化因子外顯子14跳讀式突變\n' +
         '● 主要規定1-2：初次申請時需檢具非小細胞肺癌之病理或細胞檢查報告及基因檢測方法/採檢機構資料\n' +
         '  ● 1-2規則1：非小細胞肺癌之病理或細胞檢查報告\n' +
         '  ● 1-2規則2：基因檢測方法及採檢機構資料\n\n'
    else if Reusable."初次申請" and (
      "1-1規則1-1=適用於治療轉移性非小細胞肺癌的成人病人"
      or "1-1規則1-2=其腫瘤帶有導致間質上皮轉化因子外顯子14跳讀式突變"
      or "1-2規則1"
      or "1-2規則2"
    )
      then '<主要規定一：初次使用條件>\n' +
           (if "1-1規則1-1=適用於治療轉移性非小細胞肺癌的成人病人" then '● 1-1規則1-1：適用於治療轉移性非小細胞肺癌的成人病人\n' else '') +
           (if "1-1規則1-2=其腫瘤帶有導致間質上皮轉化因子外顯子14跳讀式突變" then '● 1-1規則1-2：其腫瘤帶有導致間質上皮轉化因子外顯子14跳讀式突變\n' else '') +
           (if "1-2規則1" then '● 1-2規則1：非小細胞肺癌之病理或細胞檢查報告\n' else '') +
           (if "1-2規則2" then '● 1-2規則2：基因檢測方法及採檢機構資料\n' else '') +
           '\n'
      else '') +

  (if Reusable."續用申請" and "主要規定二"
    then '<主要規定二：續用條件>\n' +
         '● 2規則1：3個月內有影像檢查報告，且續用註記為2、醫令類別為1\n\n'
    else if Reusable."續用申請" and "2規則1"
      then '<主要規定二：續用條件>\n' +
           '● 2規則1：3個月內有影像檢查報告，且續用註記為2、醫令類別為1\n\n'
      else '') +

  (if "主要規定三"
    then '<主要規定三：藥品使用規則>\n' +
         '● 3規則1：每次申請事前審查之療程以3個月為限（參考資訊）\n' +
         '● 3規則2：每日最多處方2粒\n\n'
    else if "3規則1=每次申請事前審查之療程以3個月為限" or "3規則2=每日最多處方2粒"
      then '<主要規定三：藥品使用規則>\n' +
           (if "3規則1=每次申請事前審查之療程以3個月為限" then '● 3規則1：每次申請事前審查之療程以3個月為限（參考資訊）\n' else '') +
           (if "3規則2=每日最多處方2粒" then '● 3規則2：每日最多處方2粒\n' else '') +
           '\n'
      else '')

//============================================
// 列出「不符合」項目判斷式 - 條件或代碼不符合
//============================================

define function "不符合項目_條件或代碼不符合"():
  (if Reusable."初次申請" and not "主要規定一" and (
    (not "1-1規則1-1=適用於治療轉移性非小細胞肺癌的成人病人")
    or ("MET基因檢測資料存在" and not "1-1規則1-2=其腫瘤帶有導致間質上皮轉化因子外顯子14跳讀式突變")
    or ("1-2規則1=病理或細胞檢查報告資料存在" and not "1-2規則1")
  )
    then '<主要規定一：初次使用條件>\n' +
         (if not "1-1規則1-1=適用於治療轉移性非小細胞肺癌的成人病人" then '▲ 1-1規則1-1：未符合適用於治療轉移性非小細胞肺癌成人病人條件\n' else '') +
         (if "MET基因檢測資料存在" and not "1-1規則1-2=其腫瘤帶有導致間質上皮轉化因子外顯子14跳讀式突變" then '▲ 1-1規則1-2：未符合MET外顯子14跳讀式突變條件\n' else '') +
         (if "1-2規則1=病理或細胞檢查報告資料存在" and not "1-2規則1" then '▲ 1-2規則1：未符合非小細胞肺癌病理或細胞檢查報告條件\n' else '') +
         '\n'
    else '') +

  (if Reusable."續用申請" and (
    "影像或檢查報告資料存在" and not "2規則1"
  )
    then '<主要規定二：續用條件>\n' +
         '▲ 2規則1：未符合續用追蹤影像檢查、續用註記或醫令類別條件\n' +
         '\n'
    else '') +

  (if (
    ("療程期間資料存在" and not "3規則1=每次申請事前審查之療程以3個月為限")
    or ("3規則2=每日劑量資料存在" and not "3規則2=每日最多處方2粒")
  )
    then '<主要規定三：藥品使用規則>\n' +
         (if "療程期間資料存在" and not "3規則1=每次申請事前審查之療程以3個月為限" then '▲ 3規則1：未符合每次申請事前審查療程以3個月為限條件（參考資訊）\n' else '') +
         (if "3規則2=每日劑量資料存在" and not "3規則2=每日最多處方2粒" then '▲ 3規則2：未符合每日最多處方2粒條件\n' else '') +
         '\n'
    else '')

//============================================
// 列出「不符合」項目判斷式 - 必要資料未填寫
//============================================

define function "不符合項目_必要資料未填寫"():
  (if Reusable."初次申請" and (
    "本次申請紀錄" is null
    or not "主要疾病ICD資料存在"
    or not "病患生日資料存在"
    or not "主要疾病文字資料存在"
    or not "報告結論資料存在"
    or not "影像或檢查報告資料存在"
    or not "癌症分期資料存在"
    or not "續用註記資料存在"
    or not "醫令類別資料存在"
    or not "MET基因檢測資料存在"
    or not "1-2規則1=病理或細胞檢查報告資料存在"
    or not "1-2規則2=基因檢測方法及採檢機構資料存在"
  )
    then '<主要規定一：初次使用條件>\n' +
         (if "本次申請紀錄" is null then '▲ 1條件申請醫令：未提供Tepotinib申請醫令資料\n' else '') +
         (if not "主要疾病ICD資料存在" then '▲ 1-1規則1-1：未提供主要疾病ICD診斷資料\n' else '') +
         (if not "病患生日資料存在" then '▲ 1-1規則1-1：未提供病患生日資料\n' else '') +
         (if not "主要疾病文字資料存在" then '▲ 1-1規則1-1：未提供病摘診斷文字資料\n' else '') +
         (if not "報告結論資料存在" then '▲ 1-1規則1-1：未提供檢查報告結論資料\n' else '') +
         (if not "影像或檢查報告資料存在" then '▲ 1-1規則1-1：未提供影像或檢查報告資料\n' else '') +
         (if not "癌症分期資料存在" then '▲ 1-1規則1-1：未提供癌症分期分數或結果資料\n' else '') +
         (if not "續用註記資料存在" then '▲ 1-1規則1-1：未提供續用註記資料\n' else '') +
         (if not "醫令類別資料存在" then '▲ 1-1規則1-1：未提供醫令類別資料\n' else '') +
         (if not "MET基因檢測資料存在" then '▲ 1-1規則1-2：未提供MET基因檢測資料\n' else '') +
         (if not "1-2規則1=病理或細胞檢查報告資料存在" then '▲ 1-2規則1：未提供病理或細胞檢查報告資料\n' else '') +
         (if not "1-2規則2=基因檢測方法及採檢機構資料存在" then '▲ 1-2規則2：未提供基因檢測方法或採檢機構資料\n' else '') +
         '\n'
    else '') +

  (if Reusable."續用申請" and (
    "本次申請紀錄" is null
    or not "影像或檢查報告資料存在"
    or not "續用註記資料存在"
    or not "醫令類別資料存在"
  )
    then '<主要規定二：續用條件>\n' +
         (if "本次申請紀錄" is null then '▲ 2條件申請醫令：未提供Tepotinib申請醫令資料\n' else '') +
         (if not "影像或檢查報告資料存在" then '▲ 2規則1：未提供影像檢查報告資料\n' else '') +
         (if not "續用註記資料存在" then '▲ 2規則1：未提供續用註記資料\n' else '') +
         (if not "醫令類別資料存在" then '▲ 2規則1：未提供醫令類別資料\n' else '') +
         '\n'
    else '') +

  (if (
    "本次申請紀錄" is null
    or not "療程期間資料存在"
    or not "3規則2=每日劑量資料存在"
  )
    then '<主要規定三：藥品使用規則>\n' +
         (if "本次申請紀錄" is null then '▲ 3條件申請醫令：未提供Tepotinib申請醫令資料\n' else '') +
         (if not "療程期間資料存在" then '▲ 3規則1：未提供療程起迄日期資料（參考資訊）\n' else '') +
         (if not "3規則2=每日劑量資料存在" then '▲ 3規則2：未提供每日劑量資料\n' else '') +
         '\n'
    else '')

//============================================
// 審核結果
//============================================

define "肺癌Tepotinib申請結果_布林":
  case
    when Reusable."初次申請" then (
      "主要規定一"
      and "主要規定三_核心條件"
    )
    when Reusable."續用申請" then (
      "主要規定二"
      and "主要規定三_核心條件"
    )
    else false
  end

define "肺癌Tepotinib申請結果":
  if Reusable."初次申請" and "主要規定一" and "主要規定三_核心條件"
  then '✓通過：初次使用－肺癌 Tepotinib 用藥申請'
  else if Reusable."續用申請" and "主要規定二" and "主要規定三_核心條件"
  then '✓通過：續用－肺癌 Tepotinib 用藥申請'
  else if Reusable."初次申請"
  then '✖不通過：初次使用－肺癌 Tepotinib 用藥申請'
  else if Reusable."續用申請"
  then '✖不通過：續用－肺癌 Tepotinib 用藥申請'
  else '✖不通過：無法判定申請類型－肺癌 Tepotinib 用藥申請'

//============================================
// 報告總結
//============================================

define "報告總結":
  '\n=== 肺癌之 Tepotinib 申請審核報告 ===\n' +
  '\n※ 備註：標示為「參考資訊」之檢核項目，係供審核參酌使用，不作為最終【申請結果】判定之依據。\n' +
  '\n【申請類型】' + Reusable."申請類型" + '\n' +
  '\n【●符合項目】\n' +
  (if "符合項目"() = '' then '無\n' else "符合項目"()) +
  '\n【▲不符合項目 - 必要資料未填寫】\n' +
  (if "不符合項目_必要資料未填寫"() = '' then '無\n' else "不符合項目_必要資料未填寫"()) +
  '\n【▲不符合項目 - 條件或代碼不符合】\n' +
  (if "不符合項目_條件或代碼不符合"() = '' then '無\n' else "不符合項目_條件或代碼不符合"()) +
  '\n【申請結果】\n' +
  "肺癌Tepotinib申請結果" +
  '\n===============================================\n'
