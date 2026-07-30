//肺癌_Bevacizumab給付規定
library LCBevacizumabRule1 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

include LCCodeConcept version '1.0.0' called CodeConcept

include LCReusable version '1.0.0' called Reusable

context Patient

//============================================
// 申請紀錄
//============================================

define "本次申請紀錄":
  Reusable."LatestMedicationPlan"(CodeConcept.L01FG01exceptKC01146219)

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
define "1規則1-1=Bevacizumab與 erlotinib併用":
"本次申請起始日期" is not null
  and exists (
    [MedicationRequest] MR
      where Reusable."HasMedicationCode"(MR, CodeConcept.L01EB02)
        and Reusable."HasValidTiming"(MR)
        and Reusable."GetStartTime"(MR) = "本次申請起始日期"
  )
  and Reusable."用藥線別=1"
  and Reusable."續用註記為1"
  and Reusable."醫令類別為1"

define "1規則1-2=作為無法手術切除的轉移性(第Ⅳ期)":
Reusable."HasClaimDiagnosisText"('(?i).*手術無法切除.*')
and "3個月內有影像檢查報告"
and "癌症分期分數或結果為M≠0"

define "1規則1-3=帶有表皮生長因子受體(EGFR) Exon 21 L858R 活化性突變":
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
          where ComponentCodeCoding.code in CodeConcept.EGFRExon21L858R
        )
      )
      and RasO.value is not null
      and RasO.value is FHIR.string
      and Matches((RasO.value as FHIR.string).value, '(?i).*(mutation|變異|突變).*(positive|陽性).*')
  )

define "1規則1-4=腦轉移非鱗狀非小細胞肺癌病患的第一線治療":
Reusable."ICD-10使用C34"
    and Reusable."HasClaimDiagnosisText"('腦轉移非鱗狀非小細胞肺癌.*')
    and (
        (not "3個月內有影像檢查報告" and not "3個月內有檢查報告")
        or ("3個月內有影像檢查報告" and "3個月內有檢查報告")
    )
    and Reusable."HasReportResultString"('(?i).*(非鱗狀|Non-squamous).*(非小細胞肺癌|non-small cell  carcinoma).*')

define "1規則1":
"1規則1-1=Bevacizumab與 erlotinib併用"
and "1規則1-2=作為無法手術切除的轉移性(第Ⅳ期)"
and "1規則1-3=帶有表皮生長因子受體(EGFR) Exon 21 L858R 活化性突變"
and "1規則1-4=腦轉移非鱗狀非小細胞肺癌病患的第一線治療"

/*規則2*/
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
          where ComponentCodeCoding.code in CodeConcept.EGFRExon21L858R
        )
      )
  )

define "主要規定一":
"本次申請紀錄" is not null
and "1規則1"
and "1規則2"

//============================================
// 主要規定二：續用條件－治療持續給付
//============================================

/*規則1*/
define "2規則1=再次申請必須提出客觀證據證實無惡化":
"3個月內有影像檢查報告"
and Reusable."續用註記為2"
and Reusable."醫令類別為1"

define "主要規定二":
"本次申請紀錄" is not null
and "2規則1=再次申請必須提出客觀證據證實無惡化"

//============================================
// 主要規定三：藥品使用規則
//============================================

/*規則1*/
define "3規則1=每次申請之療程以 12 週為限":
Reusable."HasMedicationPlanPeriodWithinDays"(CodeConcept.L01FG01exceptKC01146219, 84)
and Reusable."醫令類別為1"

/*規則2*/
define "3規則2-1=Bevacizumab併用erlotinib於第一線治療時":
"本次申請起始日期" is not null
  and exists (
    [MedicationRequest] MR
      where Reusable."HasMedicationCode"(MR, CodeConcept.L01EB02)
        and Reusable."HasValidTiming"(MR)
        and Reusable."GetStartTime"(MR) = "本次申請起始日期"
  )
  and Reusable."用藥線別=1"
  and Reusable."醫令類別為1"

define "3規則2-2=與gefitinib、afatinib 僅得擇一使用":
not Reusable."HasConcurrentMedicationUse"(
    CodeConcept.L01FG01exceptKC01146219,
    CodeConcept.L01EB01 union CodeConcept.L01EB03
  )

define "3規則2":
"3規則2-1=Bevacizumab併用erlotinib於第一線治療時"
and "3規則2-2=與gefitinib、afatinib 僅得擇一使用"

/*規則3*/
define "PatientWeight":
  First(
    [Claim] C
      return First(
        C.supportingInfo Cs
          where exists (
            Cs.category.coding coding
              where coding in CodeConcept.NHIPASSupportingInfoType
                and coding.code = 'weight'
          )
          return (Cs.value as FHIR.Quantity)
      )
  )

define "PatientWeightValue":
  PatientWeight.value  // 單位：kg

define "MaxAllowedDose":
  if PatientWeightValue is not null
  then PatientWeightValue * 7.5  // 單位：mg
  else null

define "3規則3=使用劑量":
  PatientWeightValue is not null
  and exists (
    [MedicationRequest] M
    where M.intent = 'plan'
    and exists (
      M.medication.coding Cdg
      where Cdg in CodeConcept.NHIMedication
      and Cdg.code in CodeConcept.L01FG01exceptKC01146219
    )
    and exists (
      M.dosageInstruction DI
      where exists (
        DI.timing.code.coding C where C.code = 'Q3W'
      )
      and exists (
        DI.doseAndRate DR
        where DR.dose.value <= MaxAllowedDose
      )
    )
  )

define "主要規定三":
"3規則1=每次申請之療程以 12 週為限"
and "3規則2"
and "3規則3=使用劑量"

define "主要規定三_核心條件":
  "3規則3=使用劑量"

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

define "erlotinib併用醫令資料存在":
  exists (
    [MedicationRequest] MR
      where Reusable."HasMedicationCode"(MR, CodeConcept.L01EB02)
        and Reusable."HasValidTiming"(MR)
  )

define "1規則1-3=EGFR Exon 21 L858R基因檢測資料存在":
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
                where ComponentCodeCoding.code in CodeConcept.EGFRExon21L858R
            )
            and ComponentRecord.value is not null
        )
  )

define "用藥線別資料存在":
  exists (
    [Claim] C
      where exists (
        C.item I
          where exists (
            I.modifier M
              where exists (
                M.coding Cdg
                  where Cdg in CodeConcept.NHILOT
              )
          )
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
      where Reusable."IsMedicationPlan"(MR, CodeConcept.L01FG01exceptKC01146219)
  )

define "3規則2-2=併用gefitinib或afatinib醫令資料存在":
  exists (
    [MedicationRequest] MR
      where Reusable."HasMedicationCode"(
        MR,
        CodeConcept.L01EB01 union CodeConcept.L01EB03
      )
  )

define "3規則3=病患體重資料存在":
  "PatientWeightValue" is not null

define "3規則3=使用劑量資料存在":
  exists (
    [MedicationRequest] M
      where M.intent = 'plan'
        and exists (
          M.medication.coding Cdg
            where Cdg in CodeConcept.NHIMedication
              and Cdg.code in CodeConcept.L01FG01exceptKC01146219
        )
        and exists (
          M.dosageInstruction DI
            where exists (
              DI.timing.code.coding C where C.code = 'Q3W'
            )
            and exists (
              DI.doseAndRate DR
                where DR.dose.value is not null
            )
        )
  )

define "必要資料皆存在":
  (
    Reusable."初次申請" and
    "本次申請紀錄" is not null and
    "主要疾病ICD資料存在" and
    "主要疾病文字資料存在" and
    "影像或檢查報告資料存在" and
    "癌症分期資料存在" and
    "報告結論資料存在" and
    "1規則1-3=EGFR Exon 21 L858R基因檢測資料存在" and
    "用藥線別資料存在" and
    "續用註記資料存在" and
    "醫令類別資料存在" and
    "erlotinib併用醫令資料存在" and
    "療程期間資料存在" and
    "3規則3=病患體重資料存在" and
    "3規則3=使用劑量資料存在"
  )
  or (
    Reusable."續用申請" and
    "本次申請紀錄" is not null and
    "影像或檢查報告資料存在" and
    "續用註記資料存在" and
    "醫令類別資料存在" and
    "療程期間資料存在" and
    "erlotinib併用醫令資料存在" and
    "3規則3=病患體重資料存在" and
    "3規則3=使用劑量資料存在"
  )

//============================================
// 列出「符合」項目判斷式
//============================================

define function "符合項目"():
  (if Reusable."初次申請" and "主要規定一"
    then '<主要規定一：初次使用條件>\n' +
         '● 1規則1：Bevacizumab與erlotinib併用作為無法手術切除的轉移性(第Ⅳ期)、帶有EGFR Exon 21 L858R突變之腦轉移非鱗狀非小細胞肺癌第一線治療\n' +
         '  ● 1規則1-1：Bevacizumab與erlotinib併用\n' +
         '  ● 1規則1-2：作為無法手術切除的轉移性(第Ⅳ期)\n' +
         '  ● 1規則1-3：帶有EGFR Exon 21 L858R活化性突變\n' +
         '  ● 1規則1-4：腦轉移非鱗狀非小細胞肺癌病患的第一線治療\n' +
         '● 1規則2：檢附EGFR Exon 21 L858R基因檢測結果報告\n\n'
    else if Reusable."初次申請" and (
      "1規則1-1=Bevacizumab與 erlotinib併用"
      or "1規則1-2=作為無法手術切除的轉移性(第Ⅳ期)"
      or "1規則1-3=帶有表皮生長因子受體(EGFR) Exon 21 L858R 活化性突變"
      or "1規則1-4=腦轉移非鱗狀非小細胞肺癌病患的第一線治療"
      or "1規則2"
    )
      then '<主要規定一：初次使用條件>\n' +
           (if "1規則1-1=Bevacizumab與 erlotinib併用" then '● 1規則1-1：Bevacizumab與erlotinib併用\n' else '') +
           (if "1規則1-2=作為無法手術切除的轉移性(第Ⅳ期)" then '● 1規則1-2：作為無法手術切除的轉移性(第Ⅳ期)\n' else '') +
           (if "1規則1-3=帶有表皮生長因子受體(EGFR) Exon 21 L858R 活化性突變" then '● 1規則1-3：帶有EGFR Exon 21 L858R活化性突變\n' else '') +
           (if "1規則1-4=腦轉移非鱗狀非小細胞肺癌病患的第一線治療" then '● 1規則1-4：腦轉移非鱗狀非小細胞肺癌病患的第一線治療\n' else '') +
           (if "1規則2" then '● 1規則2：檢附EGFR Exon 21 L858R基因檢測結果報告\n' else '') +
           '\n'
      else '') +

  (if Reusable."續用申請" and "主要規定二"
    then '<主要規定二：續用條件－治療持續給付>\n' +
         '● 2規則1：再次申請必須提出客觀證據證實無惡化\n\n'
    else if Reusable."續用申請" and "2規則1=再次申請必須提出客觀證據證實無惡化"
      then '<主要規定二：續用條件－治療持續給付>\n' +
           '● 2規則1：再次申請必須提出客觀證據證實無惡化\n\n'
      else '') +

  (if "主要規定三"
    then '<主要規定三：藥品使用規則>\n' +
         '● 3規則1：每次申請之療程以12週為限（參考資訊）\n' +
         '● 3規則2：Bevacizumab併用erlotinib於第一線治療時，與gefitinib、afatinib僅得擇一使用（參考資訊）\n' +
         '  ● 3規則2-1：Bevacizumab併用erlotinib於第一線治療時（參考資訊）\n' +
         '  ● 3規則2-2：與gefitinib、afatinib僅得擇一使用（參考資訊）\n' +
         '● 3規則3：使用劑量符合體重換算上限\n\n'
    else if "3規則1=每次申請之療程以 12 週為限" or "3規則2" or "3規則3=使用劑量"
      then '<主要規定三：藥品使用規則>\n' +
           (if "3規則1=每次申請之療程以 12 週為限" then '● 3規則1：每次申請之療程以12週為限（參考資訊）\n' else '') +
           (if "3規則2" then '● 3規則2：Bevacizumab併用erlotinib及與gefitinib、afatinib擇一使用條件（參考資訊）\n' else '') +
           (if "3規則3=使用劑量" then '● 3規則3：使用劑量符合體重換算上限\n' else '') +
           '\n'
      else '')


//============================================
// 列出「不符合」項目判斷式 - 條件或代碼不符合
//============================================

define function "不符合項目_條件或代碼不符合"():
  (if Reusable."初次申請" and (
    ("主要疾病ICD資料存在" and not Reusable."ICD-10使用C34")
    or ("erlotinib併用醫令資料存在" and not "1規則1-1=Bevacizumab與 erlotinib併用")
    or (("主要疾病文字資料存在" or "影像或檢查報告資料存在" or "癌症分期資料存在") and not "1規則1-2=作為無法手術切除的轉移性(第Ⅳ期)")
    or ("1規則1-3=EGFR Exon 21 L858R基因檢測資料存在" and not "1規則1-3=帶有表皮生長因子受體(EGFR) Exon 21 L858R 活化性突變")
    or (("主要疾病文字資料存在" or "影像或檢查報告資料存在" or "報告結論資料存在") and not "1規則1-4=腦轉移非鱗狀非小細胞肺癌病患的第一線治療")
  )
    then '<主要規定一：初次使用條件>\n' +
         (if "主要疾病ICD資料存在" and not Reusable."ICD-10使用C34" then '▲ 1規則1-4：未符合肺癌ICD C34條件\n' else '') +
         (if "erlotinib併用醫令資料存在" and not "1規則1-1=Bevacizumab與 erlotinib併用" then '▲ 1規則1-1：未符合Bevacizumab與erlotinib併用條件\n' else '') +
         (if not "1規則1-2=作為無法手術切除的轉移性(第Ⅳ期)" then '▲ 1規則1-2：未符合無法手術切除的轉移性(第Ⅳ期)條件\n' else '') +
         (if "1規則1-3=EGFR Exon 21 L858R基因檢測資料存在" and not "1規則1-3=帶有表皮生長因子受體(EGFR) Exon 21 L858R 活化性突變" then '▲ 1規則1-3：未符合EGFR Exon 21 L858R活化性突變條件\n' else '') +
         (if not "1規則1-4=腦轉移非鱗狀非小細胞肺癌病患的第一線治療" then '▲ 1規則1-4：未符合腦轉移非鱗狀非小細胞肺癌第一線治療條件\n' else '') +
         '\n'
    else '') +

  (if Reusable."續用申請" and (
    "影像或檢查報告資料存在" and not "2規則1=再次申請必須提出客觀證據證實無惡化"
  )
    then '<主要規定二：續用條件－治療持續給付>\n' +
         '▲ 2規則1：未符合再次申請客觀證據證實無惡化條件\n' +
         '\n'
    else '') +

  (if (
    ("療程期間資料存在" and not "3規則1=每次申請之療程以 12 週為限")
    or ("erlotinib併用醫令資料存在" and not "3規則2-1=Bevacizumab併用erlotinib於第一線治療時")
    or ("3規則2-2=併用gefitinib或afatinib醫令資料存在" and not "3規則2-2=與gefitinib、afatinib 僅得擇一使用")
    or ("3規則3=病患體重資料存在" and not "3規則3=使用劑量")
  )
    then '<主要規定三：藥品使用規則>\n' +
         (if "療程期間資料存在" and not "3規則1=每次申請之療程以 12 週為限" then '▲ 3規則1：未符合每次申請之療程以12週為限條件（參考資訊）\n' else '') +
         (if "erlotinib併用醫令資料存在" and not "3規則2-1=Bevacizumab併用erlotinib於第一線治療時" then '▲ 3規則2-1：未符合Bevacizumab併用erlotinib於第一線治療條件（參考資訊）\n' else '') +
         (if "3規則2-2=併用gefitinib或afatinib醫令資料存在" and not "3規則2-2=與gefitinib、afatinib 僅得擇一使用" then '▲ 3規則2-2：未符合僅得擇一使用條件（參考資訊）\n' else '') +
         (if "3規則3=病患體重資料存在" and not "3規則3=使用劑量" then '▲ 3規則3：未符合使用劑量上限條件\n' else '') +
         '\n'
    else '')


//============================================
// 列出「不符合」項目判斷式 - 必要資料未填寫
//============================================

define function "不符合項目_必要資料未填寫"():
  (if Reusable."初次申請" and (
    "本次申請紀錄" is null
    or not "主要疾病ICD資料存在"
    or not "主要疾病文字資料存在"
    or not "影像或檢查報告資料存在"
    or not "癌症分期資料存在"
    or not "報告結論資料存在"
    or not "1規則1-3=EGFR Exon 21 L858R基因檢測資料存在"
    or not "用藥線別資料存在"
    or not "續用註記資料存在"
    or not "醫令類別資料存在"
    or not "erlotinib併用醫令資料存在"
  )
    then '<主要規定一：初次使用條件>\n' +
         (if "本次申請紀錄" is null then '▲ 1條件申請醫令：未提供Bevacizumab申請醫令資料\n' else '') +
         (if not "主要疾病ICD資料存在" then '▲ 1規則1-4：未提供主要疾病ICD診斷資料\n' else '') +
         (if not "主要疾病文字資料存在" then '▲ 1規則1-2/1規則1-4：未提供主要疾病文字診斷資料\n' else '') +
         (if not "影像或檢查報告資料存在" then '▲ 1規則1-2/1規則1-4：未提供影像或檢查報告資料\n' else '') +
         (if not "癌症分期資料存在" then '▲ 1規則1-2：未提供癌症分期資料\n' else '') +
         (if not "報告結論資料存在" then '▲ 1規則1-4：未提供報告結論資料\n' else '') +
         (if not "1規則1-3=EGFR Exon 21 L858R基因檢測資料存在" then '▲ 1規則1-3/1規則2：未提供EGFR Exon 21 L858R基因檢測資料\n' else '') +
         (if not "用藥線別資料存在" then '▲ 1規則1-1：未提供用藥線別資料\n' else '') +
         (if not "續用註記資料存在" then '▲ 1規則1-1：未提供續用註記資料\n' else '') +
         (if not "醫令類別資料存在" then '▲ 1規則1-1：未提供醫令類別資料\n' else '') +
         (if not "erlotinib併用醫令資料存在" then '▲ 1規則1-1：未提供Bevacizumab併用erlotinib之醫令資料\n' else '') +
         '\n'
    else '') +

  (if Reusable."續用申請" and (
    "本次申請紀錄" is null
    or not "影像或檢查報告資料存在"
    or not "續用註記資料存在"
    or not "醫令類別資料存在"
  )
    then '<主要規定二：續用條件－治療持續給付>\n' +
         (if "本次申請紀錄" is null then '▲ 2條件申請醫令：未提供Bevacizumab申請醫令資料\n' else '') +
         (if not "影像或檢查報告資料存在" then '▲ 2規則1：未提供影像或檢查報告資料\n' else '') +
         (if not "續用註記資料存在" then '▲ 2規則1：未提供續用註記資料\n' else '') +
         (if not "醫令類別資料存在" then '▲ 2規則1：未提供醫令類別資料\n' else '') +
         '\n'
    else '') +

  (if (
    "本次申請紀錄" is null
    or not "療程期間資料存在"
    or not "erlotinib併用醫令資料存在"
    or not "3規則3=病患體重資料存在"
    or not "3規則3=使用劑量資料存在"
  )
    then '<主要規定三：藥品使用規則>\n' +
         (if "本次申請紀錄" is null then '▲ 3條件申請醫令：未提供Bevacizumab申請醫令資料\n' else '') +
         (if not "療程期間資料存在" then '▲ 3規則1：未提供療程起迄日期資料（參考資訊）\n' else '') +
         (if not "erlotinib併用醫令資料存在" then '▲ 3規則2-1：未提供Bevacizumab併用erlotinib之醫令資料（參考資訊）\n' else '') +
         (if not "3規則3=病患體重資料存在" then '▲ 3規則3：未提供病患體重資料\n' else '') +
         (if not "3規則3=使用劑量資料存在" then '▲ 3規則3：未提供使用劑量資料\n' else '') +
         '\n'
    else '')


//============================================
// 審核結果
//============================================

define "肺癌Bevacizumab申請結果_布林":
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

define "肺癌Bevacizumab申請結果":
  if Reusable."初次申請" and "主要規定一" and "主要規定三_核心條件"
  then '✓通過：初次使用－肺癌 Bevacizumab 用藥申請'
  else if Reusable."續用申請" and "主要規定二" and "主要規定三_核心條件"
  then '✓通過：續用－肺癌 Bevacizumab 用藥申請'
  else if Reusable."初次申請"
  then '✖不通過：初次使用－肺癌 Bevacizumab 用藥申請'
  else if Reusable."續用申請"
  then '✖不通過：續用－肺癌 Bevacizumab 用藥申請'
  else '✖不通過：無法判定申請類型－肺癌 Bevacizumab 用藥申請'


//============================================
// 報告總結
//============================================

define "報告總結":
  '\n=== 肺癌之 Bevacizumab 申請審核報告 ===\n' +
  '\n※ 備註：標示為「參考資訊」之檢核項目，係供審核參酌使用，不作為最終【申請結果】判定之依據。\n' +
  '\n【申請類型】' + Reusable."申請類型" + '\n' +
  '\n【●符合項目】\n' +
  (if "符合項目"() = '' then '無\n' else "符合項目"()) +
  '\n【▲不符合項目 - 必要資料未填寫】\n' +
  (if "不符合項目_必要資料未填寫"() = '' then '無\n' else "不符合項目_必要資料未填寫"()) +
  '\n【▲不符合項目 - 條件或代碼不符合】\n' +
  (if "不符合項目_條件或代碼不符合"() = '' then '無\n' else "不符合項目_條件或代碼不符合"()) +
  '\n【申請結果】\n' +
  "肺癌Bevacizumab申請結果" +
  '\n===============================================\n'
