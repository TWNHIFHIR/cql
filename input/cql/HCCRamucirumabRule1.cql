//肝癌_Ramucirumab給付規定
library HCCRamucirumabRule1 version '1.0.0'

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
  Reusable."LatestMedicationPlan"(CodeConcept.L01FG02)

define "本次申請起始日期":
  Reusable."GetStartTime"("本次申請紀錄")

define "首次申請紀錄":
  First(
    [MedicationRequest] MR
      where Reusable."IsMedicationPlan"(MR, CodeConcept.L01FG02)
      sort by FHIRHelpers.ToDateTime((dosageInstruction[0].timing.repeat.bounds as Period).start)
  )

define "首次申請起始日期":
  Reusable."GetStartTime"("首次申請紀錄")

define "3個月內有影像檢查報告":
  Reusable."HasRecentImageReport"("本次申請起始日期", 90)

//============================================
// 主要規定一：初次使用條件
//============================================

/*規則1*/
//條件1
define "1規則1-1":
exists (
    [MedicationRequest] MR
      where Reusable."HasMedicationCode"(MR, CodeConcept.L01EX02)
        and Reusable."HasValidTiming"(MR)
        and Reusable."GetEndTime"(MR) < "本次申請起始日期"
  )
and Reusable."續用註記為1"
and Reusable."醫令類別為1"

//條件2
define "1規則1-2-1":
"3個月內有影像檢查報告"
and Reusable."癌症分期分數或結果為M≠0"

define "1規則1-2-2":
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

define "1規則1-2":
"1規則1-2-1" or "1規則1-2-2"

//條件3
define "1規則1-3-1":
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

define "簡要病摘":
exists (
    [Claim] C
      where exists (
        C.diagnosis D
          where exists (
            D.type.text T
              where Matches(T.value, '(?i).*局部治療失敗.*')
          )
      )
  )

define "手術報告":
Reusable."HasRecentOPReport"("本次申請起始日期", 360)

define "手術日期":
exists (
    [Claim] C
      where exists (
        C.procedure P
          where P.procedure is FHIR.CodeableConcept
            and exists (
              ((P.procedure as FHIR.CodeableConcept).coding) Cdg
                where Cdg.code in CodeConcept.opCode
            )
            and P.date < "本次申請起始日期"
      )
  )

define "1規則1-3-2":
"簡要病摘" and "手術報告" and "手術日期"

define "1規則1-3":
"1規則1-3-1" or "1規則1-3-2"

//條件4
define "1規則1-4":
 exists (
    [Observation] OBs
      where Reusable."IsTestObservation"(OBs)
        and exists (
          OBs.code.coding Cdg
            where Cdg in CodeConcept.LOINC
              and Cdg.code in CodeConcept."AFP"
        )
        and Reusable."IsObservationDateTimeWithinDaysBefore"(OBs, "本次申請起始日期", 90)
        and OBs.value is FHIR.Quantity
        and (OBs.value as FHIR.Quantity).value >= 400
  )

//條件5
define "成人":
"本次申請起始日期" is not null
  and Patient.birthDate is not null
  and AgeInYearsAt(date from "本次申請起始日期") >= 18

define "ICD-10使用C22":
  Reusable."ICD-10使用C22"

define "3個月內有檢查報告":
  Reusable."HasRecentMolecularReportV2"("本次申請起始日期", 90)

define "3個月內有評估報告":
Reusable."HasRecentPatReport"("本次申請起始日期", 90)

define "評估結果":
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
  )

define "1規則1-5":
"成人" and "ICD-10使用C22"
and (
    (not "3個月內有影像檢查報告" and not "3個月內有檢查報告")
    or ("3個月內有影像檢查報告" and "3個月內有檢查報告")
  )
and Reusable."癌症分期分數或結果為M≠0"
and "3個月內有評估報告"
and "評估結果"
and Reusable."續用註記為1"
and Reusable."醫令類別為1"

define "主要規定一":
"本次申請紀錄" is not null
and "1規則1-1" and "1規則1-2" and "1規則1-3" and "1規則1-4" and "1規則1-5"

//============================================
// 主要規定二：續用條件
//============================================

define "主要規定二":
"本次申請紀錄" is not null
and Reusable."HasRecentImageReport"("本次申請起始日期", 56)
and Reusable."續用註記為2"
and Reusable."醫令類別為1"

//============================================
// 主要規定三：藥品使用規則
//============================================

/*規則1*/
//條件1
define "3規則1":
Reusable."續用註記為1"
and Reusable."醫令類別為1"
and Reusable."HasMedicationPlanPeriodWithinDays"(CodeConcept.L01FG02, 84)

define "3規則2":
not Reusable."HasConcurrentMedicationUse"(
    CodeConcept.L01FG02,
    CodeConcept.L01EX05 union CodeConcept.L01FF01
  )
and Reusable."醫令類別為1"

define "主要規定三":
"3規則1" and "3規則2"

//============================================
// 檢核結果用：必要資料存在判斷
//============================================

define "Ramucirumab申請資料存在":
  Reusable."HasMedicationPlanRecord"(CodeConcept.L01FG02)

define "療程期間資料存在":
  Reusable."HasMedicationPlanTiming"(CodeConcept.L01FG02)

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

define "AFP檢驗資料存在":
  Reusable."HasTestObservationCode"(CodeConcept.AFP)

define "先前Sorafenib治療資料存在":
  exists (
    [MedicationRequest] MR
      where Reusable."HasMedicationCode"(MR, CodeConcept.L01EX02)
        and Reusable."HasValidTiming"(MR)
  )

define "手術相關資料存在":
  Reusable."手術報告資料存在"
  or exists ([Claim] C where exists (C.procedure P where P.procedure is FHIR.CodeableConcept))

define "無法手術切除說明資料存在":
  Reusable."HasClaimDiagnosisText"('(?i).*無法手術切除.*')

define "局部治療說明資料存在":
  Reusable."HasClaimDiagnosisText"('(?i).*(不適合局部治療|局部治療失敗).*')

define "必要資料皆存在":
  not (
    (Reusable."初次申請" and (
      not "Ramucirumab申請資料存在"
      or not Reusable."主要疾病ICD診斷資料存在"
      or not "癌症分期資料存在"
      or not "評估報告資料存在"
      or not "AFP檢驗資料存在"
      or not ("影像或檢查報告資料存在" or "無法手術切除說明資料存在")
      or not "局部治療說明資料存在"
    ))
    or (Reusable."續用申請" and (
      not "Ramucirumab申請資料存在"
      or not "影像報告資料存在"
    ))
    or not "療程期間資料存在"
  )

//============================================
// 列出「符合」項目判斷式
//============================================

define function "符合項目"():
  (if Reusable."初次申請" and (
      "1規則1-1" or "1規則1-2" or "1規則1-3" or "1規則1-4" or "1規則1-5"
    )
    then '<主要規定一：初次使用條件>\n' +
      (if "1規則1-1" then '● 規則1-1：先前使用Sorafenib治療已結束，且申請註記及醫令類別符合條件\n' else '') +
      (if "1規則1-2" then '● 規則1-2：符合無法手術切除或轉移性肝細胞癌條件\n' else '') +
      (if "1規則1-3" then '● 規則1-3：符合不適合局部治療或局部治療失敗條件\n' else '') +
      (if "1規則1-4" then '● 規則1-4：AFP檢驗值≧400 ng/mL\n' else '') +
      (if "1規則1-5" then '● 規則1-5：符合成人、C22、Child-Pugh A、申請註記及醫令類別條件\n' else '') +
      '\n'
    else '') +
  (if Reusable."續用申請" and "主要規定二"
    then '<主要規定二：續用條件>\n● 續用規則1：8週內有影像檢查報告，且申請註記與醫令類別符合條件\n\n'
    else '') +
  (if ("3規則1" or "3規則2")
    then '<主要規定三：藥品使用規則>\n' +
      (if "3規則1" then '● 規則3-1：每次申請事前審查之療程以12週為限（參考資訊）\n' else '') +
      (if "3規則2" then '● 規則3-2：未與Regorafenib或Nivolumab併用（參考資訊）\n' else '') +
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
      not "Ramucirumab申請資料存在"
      or not Reusable."主要疾病ICD診斷資料存在"
      or not "癌症分期資料存在"
      or not "評估報告資料存在"
      or not "AFP檢驗資料存在"
      or not ("影像或檢查報告資料存在" or "無法手術切除說明資料存在")
      or not "局部治療說明資料存在"
    )
    then '<主要規定一：初次使用條件>\n' +
      (if not "Ramucirumab申請資料存在" then '▲ 申請醫令：未提供Ramucirumab申請醫令資料\n' else '') +
      (if not ("影像或檢查報告資料存在" or "無法手術切除說明資料存在") then '▲ 規則1-2：未提供影像檢查報告或無法手術切除相關說明\n' else '') +
      (if not "局部治療說明資料存在" then '▲ 規則1-3：未提供不適合局部治療或局部治療失敗相關說明\n' else '') +
      (if not "AFP檢驗資料存在" then '▲ 規則1-4：未提供AFP檢驗資料\n' else '') +
      (if not Reusable."主要疾病ICD診斷資料存在" then '▲ 規則1-5：未提供主要疾病ICD診斷資料\n' else '') +
      (if not "癌症分期資料存在" then '▲ 規則1-2/1-5：未提供癌症分期資料\n' else '') +
      (if not "評估報告資料存在" then '▲ 規則1-5：未提供Child-Pugh評估資料\n' else '') +
      '\n'
    else '') +
  (if Reusable."續用申請" and (not "Ramucirumab申請資料存在" or not "影像報告資料存在")
    then '<主要規定二：續用條件>\n' +
      (if not "Ramucirumab申請資料存在" then '▲ 申請醫令：未提供Ramucirumab申請醫令資料\n' else '') +
      (if not "影像報告資料存在" then '▲ 續用規則1：未提供8週內影像檢查報告\n' else '') +
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
      ("先前Sorafenib治療資料存在" and not "1規則1-1")
      or (("影像或檢查報告資料存在" or "無法手術切除說明資料存在") and not "1規則1-2")
      or (("局部治療說明資料存在" or "手術相關資料存在") and not "1規則1-3")
      or ("AFP檢驗資料存在" and not "1規則1-4")
      or ((Reusable."主要疾病ICD診斷資料存在" or "癌症分期資料存在" or "評估報告資料存在") and not "1規則1-5")
    )
    then '<主要規定一：初次使用條件>\n' +
      (if "先前Sorafenib治療資料存在" and not "1規則1-1" then '▲ 規則1-1：先前Sorafenib治療紀錄、申請註記或醫令類別不符合條件\n' else '') +
      (if ("影像或檢查報告資料存在" or "無法手術切除說明資料存在") and not "1規則1-2" then '▲ 規則1-2：影像、分期或無法手術切除說明不符合條件\n' else '') +
      (if ("局部治療說明資料存在" or "手術相關資料存在") and not "1規則1-3" then '▲ 規則1-3：局部治療相關說明或手術報告不符合條件\n' else '') +
      (if "AFP檢驗資料存在" and not "1規則1-4" then '▲ 規則1-4：AFP檢驗值未達400 ng/mL門檻\n' else '') +
      (if (Reusable."主要疾病ICD診斷資料存在" or "癌症分期資料存在" or "評估報告資料存在") and not "1規則1-5" then '▲ 規則1-5：年齡、ICD、分期、Child-Pugh、申請註記或醫令類別不符合條件\n' else '') +
      '\n'
    else '') +
  (if Reusable."續用申請" and "影像報告資料存在" and not "主要規定二"
    then '<主要規定二：續用條件>\n▲ 續用規則1：8週內影像檢查報告、申請註記或醫令類別不符合續用條件\n\n'
    else '') +
  (if ("療程期間資料存在" and not "3規則1") or not "3規則2"
    then '<主要規定三：藥品使用規則>\n' +
      (if "療程期間資料存在" and not "3規則1" then '▲ 規則3-1：每次申請事前審查之療程超過12週上限（參考資訊）\n' else '') +
      (if not "3規則2" then '▲ 規則3-2：因與Regorafenib或Nivolumab併用，故不符合本藥品之使用規則（參考資訊）\n' else '') +
      '\n'
    else '')

//============================================
// 審核結果
//============================================

define "肝癌Ramucirumab申請結果_布林":
  case
    when Reusable."初次申請" then "主要規定一"
    when Reusable."續用申請" then "主要規定二"
    else false
  end

define "肝癌Ramucirumab申請結果":
  if Reusable."初次申請" and "肝癌Ramucirumab申請結果_布林"
  then '✓通過：初次使用－肝癌 Ramucirumab 用藥申請'
  else if Reusable."續用申請" and "肝癌Ramucirumab申請結果_布林"
  then '✓通過：續用－肝癌 Ramucirumab 用藥申請'
  else if Reusable."初次申請"
  then '✖不通過：初次使用－肝癌 Ramucirumab 用藥申請'
  else if Reusable."續用申請"
  then '✖不通過：續用－肝癌 Ramucirumab 用藥申請'
  else '✖不通過：無法判定申請類型－肝癌 Ramucirumab 用藥申請'

//============================================
// 審核報告總結
//============================================

define "報告總結":
  '\n=== 肝癌 Ramucirumab 申請審核報告 ===\n' +
  '\n※ 備註：標示為「參考資訊」之檢核項目，係供審核參酌使用，不作為最終【申請結果】判定之依據。\n' +
  '\n【申請類型】' + Reusable."申請類型" + '\n' +
  '\n【●符合項目】\n' +
  (if "符合項目"() = '' then '無\n' else "符合項目"()) +
  '\n【▲不符合項目 - 必要資料未填寫】\n' +
  (if "不符合項目_必要資料未填寫"() = '' then '無\n' else "不符合項目_必要資料未填寫"()) +
  '\n【▲不符合項目 - 條件或代碼不符合】\n' +
  (if "不符合項目_條件或代碼不符合"() = '' then '無\n' else "不符合項目_條件或代碼不符合"()) +
  '\n【申請結果】\n' +
  "肝癌Ramucirumab申請結果" +
  '\n===============================================\n'