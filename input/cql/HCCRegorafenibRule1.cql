//肝癌_Regorafenib給付規定
library HCCRegorafenibRule1 version '1.0.0'

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
  Reusable."LatestMedicationPlan"(CodeConcept.L01EX05)

define "本次申請起始日期":
  Reusable."GetStartTime"("本次申請紀錄")

define "首次申請紀錄":
  First(
    [MedicationRequest] MR
      where Reusable."IsMedicationPlan"(MR, CodeConcept.L01EX05)
      sort by FHIRHelpers.ToDateTime((dosageInstruction[0].timing.repeat.bounds as Period).start)
  )

define "12周內有影像檢查報告":
  Reusable."HasRecentImageReport"("本次申請起始日期", 84)

//============================================
// 主要規定一：初次使用條件
//============================================

/*規則1*/
//條件1
define "1規則1-1":
Reusable."ICD-10使用C22"
and Reusable."HasRecentMolecularReport"("本次申請起始日期", 90)
and Reusable."續用註記為1"
and Reusable."醫令類別為1"

//條件2
define "1規則1-2":
Reusable."ICD-10使用C22"
and "12周內有影像檢查報告"
and Reusable."癌症分期分數或結果為M≠0"

//條件3
define "簡要病摘-無法手術切除":
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

define "簡要病摘-不適合局部治療":
exists (
    [Claim] C
      where exists (
        C.diagnosis D
          where exists (
            D.type.text T
              where Matches(T.value, '(?i).*不適合局部治療.*')
          )
      )
  )

define "1規則1-3-1":
"簡要病摘-無法手術切除" and "12周內有影像檢查報告"

define "1規則1-3-2":
"簡要病摘-不適合局部治療" and "12周內有影像檢查報告"

define "1規則1-3-3":
"12周內有影像檢查報告"
and Reusable."HasRecentOPReport"("本次申請起始日期", 360)

define "1規則1-3":
"1規則1-3-1" and "1規則1-3-2" or "1規則1-3-3"

//條件4
define "1規則1-4":
exists (
    [MedicationRequest] MR
      where Reusable."HasMedicationCode"(MR, CodeConcept.L01EX02)
        and Reusable."HasValidTiming"(MR)
        and Reusable."GetEndTime"(MR) < "本次申請起始日期"
  )

//條件5
define "1規則1-5":
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
              and Cdg.code in CodeConcept.ChildPugh
        )
        and Matches(OBs.value, '(?i).*(A|a).*')
        and Reusable."IsObservationWithinDaysBefore"(OBs, "本次申請起始日期", 90)
  )
  
//條件6
define "1規則1-6":
"本次申請起始日期" is not null
  and Patient.birthDate is not null
  and AgeInYearsAt(date from "本次申請起始日期") >= 18

define "主要規定一":
"本次申請紀錄" is not null
and "1規則1-1" and ("1規則1-2" or "1規則1-3") and "1規則1-4" and "1規則1-5" and "1規則1-6"

//============================================
// 主要規定二：續用條件
//============================================
//事前審查藥物預定處方起始日期(useSdate)
define "useSdate":
  Reusable."GetStartTime"("本次申請紀錄")

//事前審查藥物預定處方終止日期(useEdate)
define "useEdate":
  Reusable."GetEndTime"("本次申請紀錄")

//(useEdate-useSdate) <= 56天
define "用藥期間未逾56天":
  "useSdate" is not null
  and "useEdate" is not null
  and (days between "useSdate" and "useEdate") <= 56

define "主要規定二":
"本次申請紀錄" is not null
and Reusable."HasRecentImageReport"("本次申請起始日期", 56)
and Reusable."續用註記為2"
and Reusable."醫令類別為1"
and "用藥期間未逾56天"

//============================================
// 主要規定三：藥品使用規則
//============================================

//(useEdate-useSdate) <= 84天
define "用藥期間未逾84天":
  "useSdate" is not null
  and "useEdate" is not null
  and (days between "useSdate" and "useEdate") <= 84

//條件1
define "3規則1":
Reusable."續用註記為1"
and Reusable."醫令類別為1"
and "用藥期間未逾84天"

//條件2
define "3規則2":
Reusable."HasConcurrentDailyDoseAtMost"(CodeConcept.L01EX05, 4, '{tbl}', 'QD')

//條件3
define "3規則3":
not Reusable."HasConcurrentMedicationUse"(
    CodeConcept.L01FG02,
    CodeConcept.L01EX05 union CodeConcept.L01FF01
  )

define "主要規定三":
"本次申請紀錄" is not null
and "3規則1" and "3規則2" and "3規則3"

//============================================
// 檢核結果用：必要資料存在判斷
//============================================

define "Regorafenib申請資料存在":
  Reusable."HasMedicationPlanRecord"(CodeConcept.L01EX05)

define "療程期間資料存在":
  Reusable."HasMedicationPlanTiming"(CodeConcept.L01EX05)

define "影像報告資料存在":
  Reusable."影像報告資料存在"

define "分子病理報告資料存在":
  Reusable."分子病理報告資料存在"

define "影像或檢查報告資料存在":
  Reusable."影像或檢查報告資料存在"

define "癌症分期資料存在":
  Reusable."癌症分期資料存在"

define "評估報告資料存在":
  Reusable."ChildPugh評估資料存在"

define "先前Sorafenib治療資料存在":
  exists (
    [MedicationRequest] MR
      where Reusable."HasMedicationCode"(MR, CodeConcept.L01EX02)
        and Reusable."HasValidTiming"(MR)
  )

define "手術相關資料存在":
  Reusable."手術報告資料存在"
  or exists ([Claim] C where exists (C.procedure P where P.procedure is FHIR.CodeableConcept))

define "無法手術切除或不適合局部治療說明資料存在":
  Reusable."HasClaimDiagnosisText"('(?i).*(無法手術切除|不適合局部治療).*')

define "劑量資料存在":
  exists (
    [MedicationRequest] MR
    where Reusable."IsMedicationPlan"(MR, CodeConcept.L01EX05)
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

define "必要資料皆存在":
  not (
    (Reusable."初次申請" and (
      not "Regorafenib申請資料存在"
      or not Reusable."主要疾病ICD診斷資料存在"
      or not "分子病理報告資料存在"
      or not "癌症分期資料存在"
      or not ("影像或檢查報告資料存在" or "無法手術切除或不適合局部治療說明資料存在")
      or not "評估報告資料存在"
    ))
    or (Reusable."續用申請" and (
      not "Regorafenib申請資料存在"
      or not "影像報告資料存在"
    ))
    or not "療程期間資料存在"
    or not "劑量資料存在"
  )

//============================================
// 列出「符合」項目判斷式
//============================================

define function "符合項目"():
  (if Reusable."初次申請" and (
      "1規則1-1" or "1規則1-2" or "1規則1-3" or "1規則1-4" or "1規則1-5" or "1規則1-6"
    )
    then '<主要規定一：初次使用條件>\n' +
      (if "1規則1-1" then '● 規則1-1：ICD診斷C22、90天內有分子病理檢查報告，且申請註記及醫令類別符合條件\n' else '') +
      (if "1規則1-2" then '● 規則1-2：12週內有影像檢查報告且癌症分期分數或結果為M≠0\n' else '') +
      (if "1規則1-3" then '● 規則1-3：符合無法手術切除、不適合局部治療或手術報告相關條件\n' else '') +
      (if "1規則1-4" then '● 規則1-4：曾使用Sorafenib治療且已結束\n' else '') +
      (if "1規則1-5" then '● 規則1-5：90天內Child-Pugh評估結果為A\n' else '') +
      (if "1規則1-6" then '● 規則1-6：年滿18歲\n' else '') +
      '\n'
    else '') +
  (if Reusable."續用申請" and "主要規定二"
    then '<主要規定二：續用條件>\n● 續用規則1：8週內有影像檢查報告，用藥期間未逾56天，且申請註記與醫令類別符合條件\n\n'
    else '') +
  (if ("3規則1" or "3規則2" or "3規則3")
    then '<主要規定三：藥品使用規則>\n' +
      (if "3規則1" then '● 規則3-1：每次申請事前審查之療程以12週為限（參考資訊）\n' else '') +
      (if "3規則2" then '● 規則3-2：每日劑量以4錠為上限\n' else '') +
      (if "3規則3" then '● 規則3-3：未有不得併用之藥品組合情形（參考資訊）\n' else '') +
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
      not "Regorafenib申請資料存在"
      or not Reusable."主要疾病ICD診斷資料存在"
      or not "分子病理報告資料存在"
      or not "癌症分期資料存在"
      or not ("影像或檢查報告資料存在" or "無法手術切除或不適合局部治療說明資料存在")
      or not "評估報告資料存在"
    )
    then '<主要規定一：初次使用條件>\n' +
      (if not "Regorafenib申請資料存在" then '▲ 申請醫令：未提供Regorafenib申請醫令資料\n' else '') +
      (if not Reusable."主要疾病ICD診斷資料存在" then '▲ 規則1-1/1-2：未提供主要疾病ICD診斷資料\n' else '') +
      (if not "分子病理報告資料存在" then '▲ 規則1-1：未提供分子病理檢查報告資料\n' else '') +
      (if not "癌症分期資料存在" then '▲ 規則1-2：未提供癌症分期資料\n' else '') +
      (if not ("影像或檢查報告資料存在" or "無法手術切除或不適合局部治療說明資料存在") then '▲ 規則1-2/1-3：未提供影像檢查報告或無法手術切除/不適合局部治療相關說明\n' else '') +
      (if not "評估報告資料存在" then '▲ 規則1-5：未提供Child-Pugh評估資料\n' else '') +
      '\n'
    else '') +
  (if Reusable."續用申請" and (not "Regorafenib申請資料存在" or not "影像報告資料存在")
    then '<主要規定二：續用條件>\n' +
      (if not "Regorafenib申請資料存在" then '▲ 申請醫令：未提供Regorafenib申請醫令資料\n' else '') +
      (if not "影像報告資料存在" then '▲ 續用規則1：未提供8週內影像檢查報告\n' else '') +
      '\n'
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
      ((Reusable."主要疾病ICD診斷資料存在" and "分子病理報告資料存在") and not "1規則1-1")
      or ((Reusable."主要疾病ICD診斷資料存在" and "影像或檢查報告資料存在" and "癌症分期資料存在") and not "1規則1-2")
      or (("影像或檢查報告資料存在" or "無法手術切除或不適合局部治療說明資料存在" or "手術相關資料存在") and not "1規則1-3" and not "1規則1-2")
      or ("評估報告資料存在" and not "1規則1-5")
    )
    then '<主要規定一：初次使用條件>\n' +
      (if (Reusable."主要疾病ICD診斷資料存在" and "分子病理報告資料存在") and not "1規則1-1" then '▲ 規則1-1：ICD診斷或分子病理檢查報告不符合條件，或申請註記/醫令類別不符合\n' else '') +
      (if (Reusable."主要疾病ICD診斷資料存在" and "影像或檢查報告資料存在" and "癌症分期資料存在") and not "1規則1-2" then '▲ 規則1-2：ICD診斷、影像或分期資料不符合條件\n' else '') +
      (if ("影像或檢查報告資料存在" or "無法手術切除或不適合局部治療說明資料存在" or "手術相關資料存在") and not "1規則1-3" and not "1規則1-2" then '▲ 規則1-3：影像、無法手術切除/不適合局部治療說明或手術報告不符合條件\n' else '') +
      (if "評估報告資料存在" and not "1規則1-5" then '▲ 規則1-5：Child-Pugh評估結果不符合A級或超過90天\n' else '') +
      '\n'
    else '') +
  (if Reusable."續用申請" and "影像報告資料存在" and not "主要規定二"
    then '<主要規定二：續用條件>\n▲ 續用規則1：影像檢查報告時間區間、用藥期間、申請註記或醫令類別不符合續用條件\n\n'
    else '') +
  (if ("療程期間資料存在" and not "3規則1") or ("劑量資料存在" and not "3規則2") or not "3規則3"
    then '<主要規定三：藥品使用規則>\n' +
      (if "療程期間資料存在" and not "3規則1" then '▲ 規則3-1：每次申請事前審查之療程超過12週上限（參考資訊）\n' else '') +
      (if "劑量資料存在" and not "3規則2" then '▲ 規則3-2：每日劑量超過4錠上限\n' else '') +
      (if not "3規則3" then '▲ 規則3-3：資料顯示有不得併用之藥品組合情形（參考資訊）\n' else '') +
      '\n'
    else '')

//============================================
// 審核結果
//============================================

define "肝癌Regorafenib申請結果_布林":
  case
    when Reusable."初次申請" then "主要規定一" and "3規則2"
    when Reusable."續用申請" then "主要規定二" and "3規則2"
    else false
  end

define "肝癌Regorafenib申請結果":
  if Reusable."初次申請" and "肝癌Regorafenib申請結果_布林"
  then '✓通過：初次使用－肝癌 Regorafenib 用藥申請'
  else if Reusable."續用申請" and "肝癌Regorafenib申請結果_布林"
  then '✓通過：續用－肝癌 Regorafenib 用藥申請'
  else if Reusable."初次申請"
  then '✖不通過：初次使用－肝癌 Regorafenib 用藥申請'
  else if Reusable."續用申請"
  then '✖不通過：續用－肝癌 Regorafenib 用藥申請'
  else '✖不通過：無法判定申請類型－肝癌 Regorafenib 用藥申請'

//============================================
// 審核報告總結
//============================================

define "報告總結":
  '\n=== 肝癌 Regorafenib 申請審核報告 ===\n' +
  '\n※ 備註：標示為「參考資訊」之檢核項目，係供審核參酌使用，不作為最終【申請結果】判定之依據。\n' +
  '\n【申請類型】' + Reusable."申請類型" + '\n' +
  '\n【●符合項目】\n' +
  (if "符合項目"() = '' then '無\n' else "符合項目"()) +
  '\n【▲不符合項目 - 必要資料未填寫】\n' +
  (if "不符合項目_必要資料未填寫"() = '' then '無\n' else "不符合項目_必要資料未填寫"()) +
  '\n【▲不符合項目 - 條件或代碼不符合】\n' +
  (if "不符合項目_條件或代碼不符合"() = '' then '無\n' else "不符合項目_條件或代碼不符合"()) +
  '\n【申請結果】\n' +
  "肝癌Regorafenib申請結果" +
  '\n===============================================\n'