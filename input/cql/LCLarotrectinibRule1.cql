//肺癌_Larotrectinib給付規定
library LCLarotrectinibRule1 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers
include LCCodeConcept version '1.0.0' called CodeConcept
include LCReusable version '1.0.0' called Reusable

context Patient

//============================================
// 申請紀錄
//============================================

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
define "1規則1-1=NTRK 基因融合且無已知的後天阻抗性突變":
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
      and RasO.value is not null
      and RasO.value is FHIR.string
      and Matches((RasO.value as FHIR.string).value, '(?i).*fusion且無後天阻抗性突變.*')
  )

define "1規則1-2-1=轉移性實體腫瘤":
  Reusable."ICD-10使用C34"
  and Reusable."醫令類別為1"
  and "癌症分期分數或結果為M≠0"
  and (
    (not "3個月內有影像檢查報告" and not "3個月內有檢查報告")
    or ("3個月內有影像檢查報告" and "3個月內有檢查報告")
  )

define "1規則1-2-2=手術切除極可能造成嚴重病症":
  Reusable."ICD-10使用C34"
  and Reusable."HasClaimDiagnosisText"('(?i).*手術切除.*(嚴重病症|severe morbidity).*')

define "1規則1-2=轉移性實體腫瘤或手術切除極可能造成嚴重病症":
  "1規則1-2-1=轉移性實體腫瘤"
  or "1規則1-2-2=手術切除極可能造成嚴重病症"

define "1規則1-3=沒有合適的替代治療選項":
  Reusable."HasClaimDiagnosisText"('(?i).*(沒有|無).*(合適|適合).*(替代治療|alternative treatment).*')

define "1規則1=適用於有NTRK基因融合的實體腫瘤成人和兒童病人":
  "1規則1-1=NTRK 基因融合且無已知的後天阻抗性突變"
  and "1規則1-2=轉移性實體腫瘤或手術切除極可能造成嚴重病症"
  and "1規則1-3=沒有合適的替代治療選項"

/*規則2*/
define "1規則2=需檢附NTRK 基因融合檢測報告":
  Reusable."HasTestObservationWithValuePattern"(CodeConcept.NTRK, '(?i).*(fusion|融合|陽性|positive|\\+).*')
  or Reusable."HasGeneInfoObservationWithTextPattern"(CodeConcept.NTRK, '(?i).*(fusion|融合|陽性|positive|\\+).*')

/*規則3*/
define "未滿18歲":
  "本次申請起始日期" is not null
  and Reusable."IsPatientYoungerThanAgeAt"(date from "本次申請起始日期", 18)

define "1規則3-1=兒童曾接受一線治療後無效或復發":
  "未滿18歲"
  and Reusable."用藥線別≠1"

define "EGFR腫瘤基因原生型":
  Reusable."HasMarkerNegative"(CodeConcept.EGFR)

define "ALK腫瘤基因原生型":
  Reusable."HasMarkerNegative"(CodeConcept.ALK)

define "ROS-1腫瘤基因原生型":
  Reusable."HasMarkerNegative"(CodeConcept.ROS1)

define "EGFR突變":
  Reusable."HasMarkerPositive"(CodeConcept.EGFR)

define "非鱗狀":
  Reusable."HasClaimDiagnosisText"('(?i).*Adenocarcinoma, Non-squamous,非鱗狀.*')

define "鱗狀":
  Reusable."HasClaimDiagnosisText"('(?i).*鱗狀.*')
  and not "非鱗狀"

define "不適合接受化學治療":
  Reusable."HasClaimDiagnosisText"('(?i).*不適合接受化學治療.*')

define "先前已使用過platinum 類化學治療失敗":
  Reusable."HasPriorMedicationUse"(CodeConcept.L01EX12, CodeConcept.L01XA)

define "先前已使用過docetaxel或paclitaxel類治療失敗":
  Reusable."HasClaimDiagnosisText"('(?i).*(docetaxel|paclitaxel|taxane|紫杉醇).*(失敗|惡化).*')

define "先前曾接受過至少一線anti-EGFR TKI 治療失敗且產生抗性":
  Reusable."HasClaimDiagnosisText"('(?i).*anti-EGFR TKI.*(失敗|抗性|resistance).*')

define "1規則3-2=成人病人符合無合適替代治療選項之肺癌條件":
  not "未滿18歲"
  and (
    (
      "不適合接受化學治療"
      and (
        ("非鱗狀" and "EGFR腫瘤基因原生型" and "ALK腫瘤基因原生型" and "ROS-1腫瘤基因原生型")
        or ("鱗狀" and "EGFR腫瘤基因原生型" and "ALK腫瘤基因原生型")
      )
    )
    or (
      "先前已使用過platinum 類化學治療失敗"
      and "鱗狀"
      and "EGFR腫瘤基因原生型"
      and "ALK腫瘤基因原生型"
    )
    or (
      "先前已使用過platinum 類化學治療失敗"
      and "先前已使用過docetaxel或paclitaxel類治療失敗"
      and "EGFR腫瘤基因原生型"
      and "ALK腫瘤基因原生型"
      and "ROS-1腫瘤基因原生型"
    )
    or (
      "先前曾接受過至少一線anti-EGFR TKI 治療失敗且產生抗性"
      and "EGFR突變"
    )
  )

define "1規則3=兒童或成人使用條件":
  "1規則3-1=兒童曾接受一線治療後無效或復發"
  or "1規則3-2=成人病人符合無合適替代治療選項之肺癌條件"

define "主要規定一":
  "本次申請紀錄" is not null
  and "1規則1=適用於有NTRK基因融合的實體腫瘤成人和兒童病人"
  and "1規則2=需檢附NTRK 基因融合檢測報告"
  and "1規則3=兒童或成人使用條件"

//============================================
// 主要規定二：續用條件
//============================================

define "2規則1=需檢附療效評估資料證實無疾病進展":
  "前次申請紀錄" is not null
  and exists (
    [DiagnosticReport] Report
      where Reusable."IsImageReport"(Report)
        and Report.effective is not null
        and FHIRHelpers.ToDateTime(Report.effective) >= "前次申請起始日期"
        and FHIRHelpers.ToDateTime(Report.effective) <= "本次申請起始日期"
  )
  and not Reusable."HasClaimDiagnosisText"('(?i).*(疾病進展|病情惡化|progression).*')

define "主要規定二":
  "本次申請紀錄" is not null
  and "2規則1=需檢附療效評估資料證實無疾病進展"

//============================================
// 主要規定三：藥品使用規則
//============================================

define "3規則1=每次申請之療程以12週為限":
  Reusable."HasMedicationPlanPeriodWithinDays"(CodeConcept.L01EX12, 84)

define "主要規定三":
  "3規則1=每次申請之療程以12週為限"

//============================================
// 檢核結果用：必要資料存在判斷
//============================================

define "NTRK檢測資料存在":
  exists (
    [Observation] OBs
      where Reusable."IsTestObservation"(OBs)
        and exists (
          OBs.code.coding Cdg
            where Cdg in CodeConcept.LOINC
              and Cdg.code in CodeConcept.NTRK
        )
        and (OBs.value is not null or exists (OBs.interpretation I where I is not null))
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
                  and Cdg.code in CodeConcept.NTRK
            )
            and Comp.value is not null
        )
  )

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

define "療程期間資料存在":
  exists (
    [MedicationRequest] MR
      where Reusable."IsMedicationPlan"(MR, CodeConcept.L01EX12)
  )

//============================================
// 列出檢核項目
define "必要資料皆存在":
  not (
    (
      Reusable."初次申請" and (
          "本次申請紀錄" is null
          or not "NTRK檢測資料存在"
          or not "主要疾病ICD資料存在"
        )
    )
    or (
      (
          "本次申請紀錄" is null
          or not "療程期間資料存在"
        )
    )
  )


//============================================

define function "符合項目"():
  (if Reusable."初次申請" and "主要規定一"
    then '<主要規定一：初次使用條件>\n' +
         '● 1規則1：NTRK基因融合、無後天阻抗性突變，且符合轉移性或手術切除嚴重病症與無替代治療選項\n' +
         '● 1規則2：已檢附NTRK基因融合檢測報告\n' +
         '● 1規則3：兒童或成人使用條件\n\n'
    else '') +
  (if Reusable."續用申請" and "主要規定二"
    then '<主要規定二：續用條件>\n' +
         '● 2規則1：療效評估資料證實無疾病進展\n\n'
    else '') +
  (if "主要規定三"
    then '<主要規定三：藥品使用規則>\n' +
         '● 3規則1：每次申請之療程以12週為限（參考資訊）\n\n'
    else '')

define function "不符合項目_條件或代碼不符合"():
  (if Reusable."初次申請" and not "主要規定一"
    then '<主要規定一：初次使用條件>\n' +
         (if "主要疾病ICD資料存在" and not Reusable."ICD-10使用C34" then '▲ 1規則1：未符合肺癌ICD C34條件\n' else '') +
         (if "NTRK檢測資料存在" and not "1規則1-1=NTRK 基因融合且無已知的後天阻抗性突變" then '▲ 1規則1-1：未符合NTRK基因融合且無後天阻抗性突變條件\n' else '') +
         (if not "1規則1-2=轉移性實體腫瘤或手術切除極可能造成嚴重病症" then '▲ 1規則1-2：未符合轉移性實體腫瘤或手術切除嚴重病症條件\n' else '') +
         (if not "1規則1-3=沒有合適的替代治療選項" then '▲ 1規則1-3：未符合沒有合適替代治療選項條件\n' else '') +
         (if not "1規則3=兒童或成人使用條件" then '▲ 1規則3：未符合兒童或成人使用條件\n' else '') +
         '\n'
    else '') +
  (if Reusable."續用申請" and not "主要規定二"
    then '<主要規定二：續用條件>\n' +
         '▲ 2規則1：未符合療效評估資料證實無疾病進展條件\n\n'
    else '') +
  (if "療程期間資料存在" and not "主要規定三"
    then '<主要規定三：藥品使用規則>\n' +
         '▲ 3規則1：未符合每次申請之療程以12週為限條件（參考資訊）\n\n'
    else '')

define function "不符合項目_必要資料未填寫"():
  (if Reusable."初次申請" and (
    "本次申請紀錄" is null
    or not "NTRK檢測資料存在"
    or not "主要疾病ICD資料存在"
  )
    then '<主要規定一：初次使用條件>\n' +
         (if "本次申請紀錄" is null then '▲ 1條件申請醫令：未提供Larotrectinib申請醫令資料\n' else '') +
         (if not "NTRK檢測資料存在" then '▲ 1規則1/2：未提供NTRK檢測資料\n' else '') +
         (if not "主要疾病ICD資料存在" then '▲ 1規則1：未提供主要疾病ICD診斷資料\n' else '') +
         '\n'
    else '') +
  (if (
    "本次申請紀錄" is null
    or not "療程期間資料存在"
  )
    then '<主要規定三：藥品使用規則>\n' +
         (if "本次申請紀錄" is null then '▲ 3條件申請醫令：未提供Larotrectinib申請醫令資料\n' else '') +
         (if not "療程期間資料存在" then '▲ 3規則1：未提供療程起迄日期資料（參考資訊）\n' else '') +
         '\n'
    else '')

//============================================
// 審核結果
//============================================

define "肺癌Larotrectinib申請結果_布林":
  case
    when Reusable."初次申請" then (
      "主要規定一"
    )
    when Reusable."續用申請" then (
      "主要規定二"
    )
    else false
  end

define "肺癌Larotrectinib申請結果":
  if Reusable."初次申請" and "主要規定一"
  then '✓通過：初次使用－肺癌 Larotrectinib 用藥申請'
  else if Reusable."續用申請" and "主要規定二"
  then '✓通過：續用－肺癌 Larotrectinib 用藥申請'
  else if Reusable."初次申請"
  then '✖不通過：初次使用－肺癌 Larotrectinib 用藥申請'
  else if Reusable."續用申請"
  then '✖不通過：續用－肺癌 Larotrectinib 用藥申請'
  else '✖不通過：無法判定申請類型－肺癌 Larotrectinib 用藥申請'

define "報告總結":
  '\n=== 肺癌之 Larotrectinib 申請審核報告 ===\n' +
  '\n※ 備註：標示為「參考資訊」之檢核項目，係供審核參酌使用，不作為最終【申請結果】判定之依據。\n' +
  '\n【申請類型】' + Reusable."申請類型" + '\n' +
  '\n【●符合項目】\n' +
  (if "符合項目"() = '' then '無\n' else "符合項目"()) +
  '\n【▲不符合項目 - 必要資料未填寫】\n' +
  (if "不符合項目_必要資料未填寫"() = '' then '無\n' else "不符合項目_必要資料未填寫"()) +
  '\n【▲不符合項目 - 條件或代碼不符合】\n' +
  (if "不符合項目_條件或代碼不符合"() = '' then '無\n' else "不符合項目_條件或代碼不符合"()) +
  '\n【申請結果】\n' +
  "肺癌Larotrectinib申請結果" +
  '\n===============================================\n'
