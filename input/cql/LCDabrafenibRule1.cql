//非小細胞肺癌_Dabrafenib、Trametinib給付規定
library LCDabrafenibRule1 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

include LCCodeConcept version '1.0.0' called CodeConcept

include LCReusable version '1.0.0' called Reusable

context Patient

//============================================
// 主要規定一：初次使用條件
//============================================

// 本次申請紀錄（Dabrafenib與Trametinib需併用；以Dabrafenib作為日期錨點）
define "本次Dabrafenib申請紀錄":
  Reusable."LatestMedicationPlan"(CodeConcept.L01EC02)

define "本次Trametinib申請紀錄":
  Reusable."LatestMedicationPlan"(CodeConcept.L01EE01)

define "本次申請紀錄":
  "本次Dabrafenib申請紀錄"

define "本次申請紀錄皆存在":
  "本次Dabrafenib申請紀錄" is not null
  and "本次Trametinib申請紀錄" is not null

define "本次申請起始日期":
  Reusable."GetStartTime"("本次申請紀錄")

// 首次申請紀錄（開始使用申請藥物）
define "首次Dabrafenib申請紀錄":
  First(
    [MedicationRequest] MR
      where Reusable."IsMedicationPlan"(MR, CodeConcept.L01EC02)
      sort by FHIRHelpers.ToDateTime((dosageInstruction[0].timing.repeat.bounds as Period).start)
  )

define "首次Trametinib申請紀錄":
  First(
    [MedicationRequest] MR
      where Reusable."IsMedicationPlan"(MR, CodeConcept.L01EE01)
      sort by FHIRHelpers.ToDateTime((dosageInstruction[0].timing.repeat.bounds as Period).start)
  )

define "首次申請紀錄":
  "首次Dabrafenib申請紀錄"

define "首次申請起始日期":
  Reusable."GetStartTime"("首次申請紀錄")

// 前次申請紀錄（本次申請之前最近一次的申請）
define "前次Dabrafenib申請紀錄":
  Reusable."LatestMedicationPlanBefore"(CodeConcept.L01EC02, "本次申請起始日期")

define "前次Trametinib申請紀錄":
  Reusable."LatestMedicationPlanBefore"(CodeConcept.L01EE01, "本次申請起始日期")

define "前次申請紀錄":
  "前次Dabrafenib申請紀錄"

define "前次申請紀錄皆存在":
  "前次Dabrafenib申請紀錄" is not null
  and "前次Trametinib申請紀錄" is not null

define "前次申請起始日期":
  Reusable."GetStartTime"("前次申請紀錄")

/*規則1*/
//條件1:轉移性(第IV期)非小細胞肺癌第二線治療
define "ICD代碼檢核_布林值": Reusable."ICD-10使用C34"

define "醫令類別為1_布林值": Reusable."醫令類別為1"

define "12週內有影像檢查報告":
  Reusable."HasRecentImageReport"("本次申請起始日期", 84)

define "癌症分期分數或結果為M≠0":
  Reusable."癌症分期分數或結果為M≠0"

define "NSCLC註記":
  exists (
    [Claim] C
      where exists (
        C.diagnosis D
          where exists (
            D.type.text T
              where Matches(T.value, '(?i).*NSCLC.*')
          )
      )
  )

define "有檢查報告":
  exists (
    [DiagnosticReport] Report
    where Reusable."IsMolecularReport"(Report)
  )

define "1規則1-1=轉移性第IV期非小細胞肺癌第二線治療":
  Reusable."ICD-10使用C34"
  and Reusable."醫令類別為1"
  and "NSCLC註記"
  and "癌症分期分數或結果為M≠0"
  and Reusable."用藥線別=2"
  and "有檢查報告"

//條件2:先前已接受過第一線含鉑化學治療，但仍惡化
define "1規則1-2=先前已接受過第一線含鉑化學治療但仍惡化":
  "本次申請起始日期" is not null
  and exists (
    [MedicationRequest] MR
      where Reusable."HasMedicationCode"(MR, CodeConcept.L01XA)
        and Reusable."HasValidTiming"(MR)
        and Reusable."GetStartTime"(MR) < "本次申請起始日期"
  )
  and "12週內有影像檢查報告"

//條件3:使用本品無效後則不再給付該適應症相關之免疫檢查點PD-1、PD-L1抑制劑
//此條件依Excel註記「使用本品後應不用納入檢核」，不納入布林檢核。
//define "1規則1-3=使用本品後免疫檢查點抑制劑限制":

//條件4:成年
define "1規則1-4=成年":
  "本次申請起始日期" is not null
  and Patient.birthDate is not null
  and Reusable."IsPatientAdultAt"(date from "本次申請起始日期")

//條件5:非小細胞肺癌之病理或細胞檢查報告以及BRAF V600E突變檢測報告
define "1規則1-5=BRAF V600E突變陽性":
  Reusable."HasTestObservationWithInterpretationAndValuePattern"(CodeConcept.BRAF, { 'POS' }, '(?i).*(陽性|positive|mutation|突變).*')
  or Reusable."HasGeneInfoObservationWithInterpretationAndTextPattern"(CodeConcept.BRAF, { 'POS' }, '(?i).*(陽性|positive|mutation|突變).*')

define "1規則1-5=病理或細胞檢查報告以及BRAF V600E突變檢測報告":
  "有檢查報告"
  and "1規則1-5=BRAF V600E突變陽性"

define "1規則1=Dabrafenib與trametinib併用於BRAF V600E突變之轉移性第IV期非小細胞肺癌成人病人":
  "1規則1-1=轉移性第IV期非小細胞肺癌第二線治療"
  and "1規則1-2=先前已接受過第一線含鉑化學治療但仍惡化"
  and "1規則1-4=成年"
  and "1規則1-5=病理或細胞檢查報告以及BRAF V600E突變檢測報告"

define "主要規定一":
  "本次申請紀錄皆存在"
  and "1規則1=Dabrafenib與trametinib併用於BRAF V600E突變之轉移性第IV期非小細胞肺癌成人病人"

//============================================
// 主要規定二：續用條件
//============================================

//再次申請時並需附上治療後相關臨床資料，若病情惡化即不得再次申請。
define "2規則1=治療後相關臨床資料":
  "前次申請紀錄皆存在"
  and "12週內有影像檢查報告"

define "主要規定二":
  "2規則1=治療後相關臨床資料"

//============================================
// 主要規定三：藥品使用規則
//============================================

/*規則1*/
define "3規則1=每次申請以12週為限":
  Reusable."HasMedicationPlanPeriodWithinDays"(CodeConcept.L01EC02, 84)
  and Reusable."HasMedicationPlanPeriodWithinDays"(CodeConcept.L01EE01, 84)


define "主要規定三":
  "3規則1=每次申請以12週為限"

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

define "NSCLC註記資料存在":
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

define "1規則1-1=影像或檢查報告資料存在":
  "影像或檢查報告資料存在"

define "1規則1-2=含鉑化學治療資料存在":
  exists (
    [MedicationRequest] MR
      where Reusable."HasMedicationCode"(MR, CodeConcept.L01XA)
        and Reusable."HasValidTiming"(MR)
  )

define "生日資料存在":
  Patient.birthDate is not null

define "1規則1-4=生日資料存在":
  "生日資料存在"

define "1規則1-5=BRAF檢測資料存在":
  exists (
    [Observation] OBs
      where Reusable."IsTestObservation"(OBs)
        and exists (
          OBs.code.coding Cdg
            where Cdg in CodeConcept.LOINC
              and Cdg.code in CodeConcept.BRAF
        )
        and (
          OBs.value is not null
          or exists (OBs.interpretation I where I is not null)
        )
  )
  or exists (
    [Observation] OBs
      where Reusable."IsGeneInfoObservation"(OBs)
        and Reusable."IsGenePanelObservation"(OBs)
        and exists (
          OBs.component Comp
            where exists (
              Comp.code.coding Cdg
                where Cdg in CodeConcept.LOINC
                  and Cdg.code in CodeConcept.BRAF
            )
            and Comp.value is not null
        )
  )

define "2規則1=治療後相關臨床資料存在":
  "1規則1-1=影像或檢查報告資料存在"

define "3規則1=療程期間資料存在":
  "本次申請紀錄皆存在"

define "必要資料皆存在":
  not (
    (
      Reusable."初次申請" and (
          not "本次申請紀錄皆存在"
          or not "主要疾病ICD資料存在"
          or not "NSCLC註記資料存在"
          or not "癌症分期資料存在"
          or not "1規則1-1=影像或檢查報告資料存在"
          or not "1規則1-2=含鉑化學治療資料存在"
          or not "1規則1-4=生日資料存在"
          or not "1規則1-5=BRAF檢測資料存在"
        )
    )
    or (
      Reusable."續用申請" and (
          not "本次申請紀錄皆存在"
          or not "前次申請紀錄皆存在"
          or not "2規則1=治療後相關臨床資料存在"
        )
    )
    or (
      (
          not "3規則1=療程期間資料存在"
        )
    )
  )


//============================================
// 列出「符合」項目判斷式
//============================================

define function "符合項目"():
  (if Reusable."初次申請" and "主要規定一"
    then '<主要規定一：初次使用條件>\n' +
         '● 1規則1：Dabrafenib與Trametinib併用於BRAF V600E突變之轉移性第IV期非小細胞肺癌成人病人\n' +
         '  ● 1規則1-1：轉移性第IV期非小細胞肺癌第二線治療\n' +
         '  ● 1規則1-2：先前已接受過第一線含鉑化學治療但仍惡化\n' +
         '  ● 1規則1-4：成年\n' +
         '  ● 1規則1-5：病理或細胞檢查報告以及BRAF V600E突變檢測報告\n\n'
    else if Reusable."初次申請" and (
      "1規則1-1=轉移性第IV期非小細胞肺癌第二線治療"
      or "1規則1-2=先前已接受過第一線含鉑化學治療但仍惡化"
      or "1規則1-4=成年"
      or "1規則1-5=病理或細胞檢查報告以及BRAF V600E突變檢測報告"
    )
      then '<主要規定一：初次使用條件>\n' +
           (if "1規則1-1=轉移性第IV期非小細胞肺癌第二線治療" then '● 1規則1-1：轉移性第IV期非小細胞肺癌第二線治療\n' else '') +
           (if "1規則1-2=先前已接受過第一線含鉑化學治療但仍惡化" then '● 1規則1-2：先前已接受過第一線含鉑化學治療但仍惡化\n' else '') +
           (if "1規則1-4=成年" then '● 1規則1-4：成年\n' else '') +
           (if "1規則1-5=病理或細胞檢查報告以及BRAF V600E突變檢測報告" then '● 1規則1-5：病理或細胞檢查報告以及BRAF V600E突變檢測報告\n' else '') +
           '\n'
      else '') +

  (if Reusable."續用申請" and "主要規定二"
    then '<主要規定二：續用條件>\n' +
         '● 2規則1：再次申請時附上治療後相關臨床資料\n\n'
    else if Reusable."續用申請" and "2規則1=治療後相關臨床資料"
      then '<主要規定二：續用條件>\n' +
           '● 2規則1：治療後相關臨床資料\n\n'
      else '') +

  (if "主要規定三"
    then '<主要規定三：藥品使用規則>\n' +
         '● 3規則1：每次申請以12週為限（參考資訊）\n\n'
    else if "3規則1=每次申請以12週為限"
      then '<主要規定三：藥品使用規則>\n' +
           (if "3規則1=每次申請以12週為限" then '● 3規則1：每次申請以12週為限（參考資訊）\n' else '') +
           '\n'
      else '')

//============================================
// 列出「不符合」項目判斷式 - 條件或代碼不符合
//============================================

define function "不符合項目_條件或代碼不符合"():
  (if Reusable."初次申請" and not "主要規定一" and (
    ("主要疾病ICD資料存在" and not Reusable."ICD-10使用C34")
    or ("癌症分期資料存在" and not "癌症分期分數或結果為M≠0")
    or ("1規則1-1=影像或檢查報告資料存在" and not ("12週內有影像檢查報告" or "有檢查報告"))
    or ("1規則1-2=含鉑化學治療資料存在" and not "1規則1-2=先前已接受過第一線含鉑化學治療但仍惡化")
    or ("1規則1-4=生日資料存在" and not "1規則1-4=成年")
    or ("1規則1-5=BRAF檢測資料存在" and not "1規則1-5=BRAF V600E突變陽性")
  )
    then '<主要規定一：初次使用條件>\n' +
         (if "主要疾病ICD資料存在" and not Reusable."ICD-10使用C34" then '▲ 1條件ICD代碼檢核：未符合主要疾病ICD代碼C34條件\n' else '') +
         (if "NSCLC註記資料存在" and not "NSCLC註記" then '▲ 1規則1-1：未符合NSCLC註記條件\n' else '') +
         (if "癌症分期資料存在" and not "癌症分期分數或結果為M≠0" then '▲ 1規則1-1：未符合癌症分期分數或結果M≠0條件\n' else '') +
         (if "1規則1-1=影像或檢查報告資料存在" and not ("12週內有影像檢查報告" or "有檢查報告") then '▲ 1規則1-1：未符合影像或檢查報告條件\n' else '') +
         (if "1規則1-2=含鉑化學治療資料存在" and not "1規則1-2=先前已接受過第一線含鉑化學治療但仍惡化" then '▲ 1規則1-2：未符合先前含鉑化學治療且仍惡化條件\n' else '') +
         (if "1規則1-4=生日資料存在" and not "1規則1-4=成年" then '▲ 1規則1-4：未符合成年條件\n' else '') +
         (if "1規則1-5=BRAF檢測資料存在" and not "1規則1-5=BRAF V600E突變陽性" then '▲ 1規則1-5：未符合BRAF V600E突變陽性條件\n' else '') +
         '\n'
    else '') +

  (if Reusable."續用申請" and "2規則1=治療後相關臨床資料存在" and not "2規則1=治療後相關臨床資料"
    then '<主要規定二：續用條件>\n' +
         '▲ 2規則1：未符合再次申請治療後相關臨床資料條件\n\n'
    else '') +

  (if (
    ("3規則1=療程期間資料存在" and not "3規則1=每次申請以12週為限")
  )
    then '<主要規定三：藥品使用規則>\n' +
         (if "3規則1=療程期間資料存在" and not "3規則1=每次申請以12週為限" then '▲ 3規則1：未符合每次申請以12週為限條件（參考資訊）\n' else '') +
         '\n'
    else '')

//============================================
// 列出「不符合」項目判斷式 - 必要資料未填寫
//============================================

define function "不符合項目_必要資料未填寫"():
  (if Reusable."初次申請" and (
    not "本次申請紀錄皆存在"
    or not "主要疾病ICD資料存在"
    or not "NSCLC註記資料存在"
    or not "癌症分期資料存在"
    or not "1規則1-1=影像或檢查報告資料存在"
    or not "1規則1-2=含鉑化學治療資料存在"
    or not "1規則1-4=生日資料存在"
    or not "1規則1-5=BRAF檢測資料存在"
  )
    then '<主要規定一：初次使用條件>\n' +
         (if "本次Dabrafenib申請紀錄" is null then '▲ 1條件申請醫令：未提供Dabrafenib申請醫令資料\n' else '') +
         (if "本次Trametinib申請紀錄" is null then '▲ 1條件申請醫令：未提供Trametinib申請醫令資料\n' else '') +
         (if not "主要疾病ICD資料存在" then '▲ 1條件ICD代碼檢核：未提供主要疾病ICD診斷資料\n' else '') +
         (if not "NSCLC註記資料存在" then '▲ 1規則1-1：未提供NSCLC註記資料\n' else '') +
         (if not "癌症分期資料存在" then '▲ 1規則1-1：未提供癌症分期分數或結果資料\n' else '') +
         (if not "1規則1-1=影像或檢查報告資料存在" then '▲ 1規則1-1：未提供影像報告或檢查報告資料\n' else '') +
         (if not "1規則1-2=含鉑化學治療資料存在" then '▲ 1規則1-2：未提供含鉑化學治療資料\n' else '') +
         (if not "1規則1-4=生日資料存在" then '▲ 1規則1-4：未提供出生日期資料\n' else '') +
         (if not "1規則1-5=BRAF檢測資料存在" then '▲ 1規則1-5：未提供BRAF V600E突變檢測資料\n' else '') +
         '\n'
    else '') +

  (if Reusable."續用申請" and (
    not "本次申請紀錄皆存在"
    or not "前次申請紀錄皆存在"
    or not "2規則1=治療後相關臨床資料存在"
  )
    then '<主要規定二：續用條件>\n' +
         (if "本次Dabrafenib申請紀錄" is null then '▲ 2條件申請醫令：未提供本次Dabrafenib申請醫令資料\n' else '') +
         (if "本次Trametinib申請紀錄" is null then '▲ 2條件申請醫令：未提供本次Trametinib申請醫令資料\n' else '') +
         (if "前次Dabrafenib申請紀錄" is null then '▲ 2條件前次申請：未提供前次Dabrafenib申請資料\n' else '') +
         (if "前次Trametinib申請紀錄" is null then '▲ 2條件前次申請：未提供前次Trametinib申請資料\n' else '') +
         (if not "2規則1=治療後相關臨床資料存在" then '▲ 2規則1：未提供治療後相關臨床資料\n' else '') +
         '\n'
    else '') +

  (if (
    not "3規則1=療程期間資料存在"
  )
    then '<主要規定三：藥品使用規則>\n' +
         (if not "3規則1=療程期間資料存在" then '▲ 3規則1：未提供療程起迄日期資料（參考資訊）\n' else '') +
         '\n'
    else '')

//============================================
// 審核結果
//============================================

define "肺癌Dabrafenib申請結果_布林":
  case
    when Reusable."初次申請" then (
      "主要規定一"
    )
    when Reusable."續用申請" then (
      "主要規定二"
    )
    else false
  end

define "肺癌Dabrafenib申請結果":
  if Reusable."初次申請" and "主要規定一"
  then '✓通過：初次使用－肺癌 Dabrafenib/Trametinib 用藥申請'
  else if Reusable."續用申請" and "主要規定二"
  then '✓通過：續用－肺癌 Dabrafenib/Trametinib 用藥申請'
  else if Reusable."初次申請"
  then '✖不通過：初次使用－肺癌 Dabrafenib/Trametinib 用藥申請'
  else if Reusable."續用申請"
  then '✖不通過：續用－肺癌 Dabrafenib/Trametinib 用藥申請'
  else '✖不通過：無法判定申請類型－肺癌 Dabrafenib/Trametinib 用藥申請'

//============================================
// 報告總結
//============================================

define "報告總結":
  '\n=== 肺癌之 Dabrafenib/Trametinib 申請審核報告 ===\n' +
  '\n※ 備註：標示為「參考資訊」之檢核項目，係供審核參酌使用，不作為最終【申請結果】判定之依據。\n' +
  '\n【申請類型】' + Reusable."申請類型" + '\n' +
  '\n【●符合項目】\n' +
  (if "符合項目"() = '' then '無\n' else "符合項目"()) +
  '\n【▲不符合項目 - 必要資料未填寫】\n' +
  (if "不符合項目_必要資料未填寫"() = '' then '無\n' else "不符合項目_必要資料未填寫"()) +
  '\n【▲不符合項目 - 條件或代碼不符合】\n' +
  (if "不符合項目_條件或代碼不符合"() = '' then '無\n' else "不符合項目_條件或代碼不符合"()) +
  '\n【申請結果】\n' +
  "肺癌Dabrafenib申請結果" +
  '\n===============================================\n'
