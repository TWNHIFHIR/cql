//肝癌_Lenvatinib給付規定
library HCCLenvatinibRule1 version '1.0.0'

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
  Reusable."LatestMedicationPlan"(CodeConcept.L01EX08)

define "本次申請起始日期":
  Reusable."GetStartTime"("本次申請紀錄")

define "3個月內有影像檢查報告":
  Reusable."HasRecentImageReport"("本次申請起始日期", 90)

define "癌症分期分數或結果為M≠0":
  Reusable."癌症分期分數或結果為M≠0"

//============================================
// 主要規定一：初次使用條件
//============================================

/*規則1*/
//條件1
define "1規則1-1-1=三個月內有影像檢查報告且癌症分期分數或結果為M≠0":
"3個月內有影像檢查報告"
and "癌症分期分數或結果為M≠0"

define "1規則1-1-2=簡要病摘為無法手術切除":
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

define "1規則1-1=無法手術切除或轉移性肝細胞癌":
"1規則1-1-1=三個月內有影像檢查報告且癌症分期分數或結果為M≠0" or "1規則1-1-2=簡要病摘為無法手術切除"

//條件2
define "1規則1-2-1=不適合局部治療":
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
  Reusable."HasSurgeryBeforeDate"("本次申請起始日期")

define "1規則1-2-2=局部治療失敗且有手術報告及手術日期":
"簡要病摘" and "手術報告" and "手術日期"

define "1規則1-2=不適合局部治療或局部治療失敗":
"1規則1-2-1=不適合局部治療" or "1規則1-2-2=局部治療失敗且有手術報告及手術日期"

//條件3
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
  Reusable."HasChildPughA"

define "1規則1-3=成人且Child-Pugh A並符合申請註記及醫令類別":
"成人" and "ICD-10使用C22"
and (
    (not "3個月內有影像檢查報告" and not "3個月內有檢查報告")
    or ("3個月內有影像檢查報告" and "3個月內有檢查報告")
  )
and "癌症分期分數或結果為M≠0"
and "3個月內有評估報告"
and "評估結果"
and Reusable."續用註記為1"
and Reusable."醫令類別為1"

//條件4
define "1規則1-4-1=三個月內影像證實轉移":
"3個月內有影像檢查報告" and "癌症分期分數或結果為M≠0"

define "1規則1-4-2=三個月內有影像檢查報告":
"3個月內有影像檢查報告"

define "12個月內符合opCode之處置日期":
  flatten(
    [Claim] C
      return
        C.procedure P
          where P.procedure is FHIR.CodeableConcept
            and exists (
              ((P.procedure as FHIR.CodeableConcept).coding) Cdg
                where Cdg.code in CodeConcept.opCodeV2
            )
            and P.date is not null
            and P.date <= "本次申請起始日期"
            and (days between P.date and "本次申請起始日期") <= 360
          return P.date
  )

define "12個月內局部治療達3次以上":
  Count("12個月內符合opCode之處置日期") >= 3

define "1規則1-4-3=十二個月內局部治療達3次以上":
Reusable."HasRecentOPReportV2"("本次申請起始日期", 360)
and "12個月內局部治療達3次以上"
and Reusable."續用註記為1"
and Reusable."醫令類別為1"

define "1規則1-4=影像或局部治療次數相關條件":
"1規則1-4-1=三個月內影像證實轉移" or "1規則1-4-2=三個月內有影像檢查報告" or "1規則1-4-3=十二個月內局部治療達3次以上"

//主要規定一
define "主要規定一":
"本次申請紀錄" is not null
and Reusable."初次申請"
and "1規則1-1=無法手術切除或轉移性肝細胞癌" and "1規則1-2=不適合局部治療或局部治療失敗" and "1規則1-3=成人且Child-Pugh A並符合申請註記及醫令類別" and "1規則1-4=影像或局部治療次數相關條件"

//============================================
// 主要規定二：續用條件
//============================================

//主要規定二
define "主要規定二":
"本次申請紀錄" is not null
and Reusable."續用申請"
and "3個月內有影像檢查報告"
and Reusable."續用註記為2"
and Reusable."醫令類別為1"

//============================================
// 主要規定三：藥品使用規則
//============================================

/*規則1*/
//條件1
define "3規則1=每次申請事前審查之療程以3個月為限":
Reusable."續用註記為1"
and Reusable."醫令類別為1"
and Reusable."HasMedicationPlanPeriodWithinMonths"(CodeConcept.L01EX08, 3)

/*規則2*/
//條件1
define "3規則2=不得與指定藥品併用":
not (
  Reusable."HasConcurrentMedicationUse"(CodeConcept.L01EX08, CodeConcept.L01EX02)
  or (
    Reusable."HasConcurrentMedicationUse"(CodeConcept.L01EX08, CodeConcept.L01FF05)
    and Reusable."HasConcurrentMedicationUse"(CodeConcept.L01EX08, CodeConcept.L01FG01)
  )
  or (
    Reusable."HasConcurrentMedicationUse"(CodeConcept.L01EX08, CodeConcept.L01FX20)
    and Reusable."HasConcurrentMedicationUse"(CodeConcept.L01EX08, CodeConcept.L01FF03)
  )
)
and Reusable."醫令類別為1"

//主要規定三
define "主要規定三":
"本次申請紀錄" is not null
and "3規則1=每次申請事前審查之療程以3個月為限"
and "3規則2=不得與指定藥品併用"

//============================================
// 檢核結果用：必要資料存在判斷
//============================================

define "Lenvatinib申請資料存在":
  Reusable."HasMedicationPlanRecord"(CodeConcept.L01EX08)

define "療程期間資料存在":
  Reusable."HasMedicationPlanTiming"(CodeConcept.L01EX08)

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

define "手術相關資料存在":
  Reusable."手術報告資料存在"
  or exists ([Claim] C where exists (C.procedure P where P.procedure is FHIR.CodeableConcept))

define "局部治療說明資料存在":
  Reusable."HasClaimDiagnosisText"('(?i).*(不適合局部治療|局部治療失敗).*')

//============================================
// 列出「符合」項目判斷式
//============================================

define function "符合項目"():
  (if Reusable."初次申請" and (
      "1規則1-1=無法手術切除或轉移性肝細胞癌" or "1規則1-2=不適合局部治療或局部治療失敗" or "1規則1-3=成人且Child-Pugh A並符合申請註記及醫令類別" or "1規則1-4=影像或局部治療次數相關條件"
    )
    then '<主要規定一：初次使用條件>\n' +
      (if "1規則1-1=無法手術切除或轉移性肝細胞癌" then '● 規則1-1：符合無法手術切除或轉移性肝細胞癌條件\n' else '') +
      (if "1規則1-2=不適合局部治療或局部治療失敗" then '● 規則1-2：符合不適合局部治療或局部治療失敗條件\n' else '') +
      (if "1規則1-3=成人且Child-Pugh A並符合申請註記及醫令類別" then '● 規則1-3：符合成人、C22、Child-Pugh A、申請註記及醫令類別條件\n' else '') +
      (if "1規則1-4=影像或局部治療次數相關條件" then '● 規則1-4：符合影像或局部治療次數相關條件\n' else '') +
      '\n'
    else '') +
  (if Reusable."續用申請" and "主要規定二"
    then '<主要規定二：續用條件>\n● 續用規則1：提出客觀證據（如：影像學）證實無惡化\n\n'
    else '') +
  (if ("3規則1=每次申請事前審查之療程以3個月為限" or "3規則2=不得與指定藥品併用")
    then '<主要規定三：藥品使用規則>\n' +
      (if "3規則1=每次申請事前審查之療程以3個月為限" then '● 規則3-1：每次申請事前審查之療程以3個月為限（參考資訊）\n' else '') +
      (if "3規則2=不得與指定藥品併用" then '● 規則3-2：未與不得併用藥品併用（參考資訊）\n' else '') +
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
      not "Lenvatinib申請資料存在"
      or not Reusable."主要疾病ICD診斷資料存在"
      or not "癌症分期資料存在"
      or not "評估報告資料存在"
      or not "局部治療說明資料存在"
    )
    then '<主要規定一：初次使用條件>\n' +
      (if not "Lenvatinib申請資料存在" then '▲ 申請醫令：未提供Lenvatinib申請醫令資料\n' else '') +
      (if not Reusable."主要疾病ICD診斷資料存在" then '▲ 規則1-3：未提供主要疾病ICD診斷資料\n' else '') +
      (if not "癌症分期資料存在" then '▲ 規則1-1/1-3/1-4：未提供癌症分期資料\n' else '') +
      (if not "評估報告資料存在" then '▲ 規則1-3：未提供Child-Pugh評估資料\n' else '') +
      (if not "局部治療說明資料存在" then '▲ 規則1-2：未提供不適合局部治療或局部治療失敗相關說明\n' else '') +
      '\n'
    else '') +
  (if Reusable."續用申請" and (not "Lenvatinib申請資料存在" or not "影像報告資料存在")
    then '<主要規定二：續用條件>\n' +
      (if not "Lenvatinib申請資料存在" then '▲ 申請醫令：未提供Lenvatinib申請醫令資料\n' else '') +
      (if not "影像報告資料存在" then '▲ 續用規則1：未提供客觀證據（如：影像學）\n' else '') +
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
      ("影像或檢查報告資料存在" and not "1規則1-1=無法手術切除或轉移性肝細胞癌")
      or ("局部治療說明資料存在" and not "1規則1-2=不適合局部治療或局部治療失敗")
      or ((Reusable."主要疾病ICD診斷資料存在" or "癌症分期資料存在" or "評估報告資料存在") and not "1規則1-3=成人且Child-Pugh A並符合申請註記及醫令類別")
      or (("影像報告資料存在" or "手術相關資料存在") and not "1規則1-4=影像或局部治療次數相關條件")
    )
    then '<主要規定一：初次使用條件>\n' +
      (if "影像或檢查報告資料存在" and not "1規則1-1=無法手術切除或轉移性肝細胞癌" then '▲ 規則1-1：影像、分期或診斷文字不符合無法手術切除或轉移性條件\n' else '') +
      (if "局部治療說明資料存在" and not "1規則1-2=不適合局部治療或局部治療失敗" then '▲ 規則1-2：局部治療相關說明不符合條件\n' else '') +
      (if (Reusable."主要疾病ICD診斷資料存在" or "癌症分期資料存在" or "評估報告資料存在") and not "1規則1-3=成人且Child-Pugh A並符合申請註記及醫令類別" then '▲ 規則1-3：年齡、ICD、分期、Child-Pugh、申請註記或醫令類別不符合條件\n' else '') +
      (if ("影像報告資料存在" or "手術相關資料存在") and not "1規則1-4=影像或局部治療次數相關條件" then '▲ 規則1-4：影像或局部治療次數相關條件不符合\n' else '') +
      '\n'
    else '') +
  (if Reusable."續用申請" and "影像報告資料存在" and not "主要規定二"
    then '<主要規定二：續用條件>\n▲ 續用規則1：影像證據、申請註記或醫令類別不符合續用條件\n\n'
    else '') +
  (if (("療程期間資料存在" and not "3規則1=每次申請事前審查之療程以3個月為限") or not "3規則2=不得與指定藥品併用")
    then '<主要規定三：藥品使用規則>\n' +
      (if "療程期間資料存在" and not "3規則1=每次申請事前審查之療程以3個月為限" then '▲ 規則3-1：每次申請事前審查之療程超過3個月上限（參考資訊）\n' else '') +
      (if not "3規則2=不得與指定藥品併用" then '▲ 規則3-2：因與指定藥品併用，故不符合本藥品之使用規則（參考資訊）\n' else '') +
      '\n'
    else '')

//============================================
// 審核結果
//============================================

define "肝癌Lenvatinib申請結果_布林":
  case
    when Reusable."初次申請" then "主要規定一"
    when Reusable."續用申請" then "主要規定二"
    else false
  end

define "肝癌Lenvatinib申請結果":
  if Reusable."初次申請" and "肝癌Lenvatinib申請結果_布林"
  then '✓通過：初次使用－肝癌 Lenvatinib 用藥申請'
  else if Reusable."續用申請" and "肝癌Lenvatinib申請結果_布林"
  then '✓通過：續用－肝癌 Lenvatinib 用藥申請'
  else if Reusable."初次申請"
  then '✖不通過：初次使用－肝癌 Lenvatinib 用藥申請'
  else if Reusable."續用申請"
  then '✖不通過：續用－肝癌 Lenvatinib 用藥申請'
  else '✖不通過：無法判定申請類型－肝癌 Lenvatinib 用藥申請'

//============================================
// 審核報告總結
//============================================

define "報告總結":
  '\n=== 肝癌 Lenvatinib 申請審核報告 ===\n' +
  '\n※ 備註：標示為「參考資訊」之檢核項目，係供審核參酌使用，不作為最終【申請結果】判定之依據。\n' +
  '\n【申請類型】' + Reusable."申請類型" + '\n' +
  '\n【●符合項目】\n' +
  (if "符合項目"() = '' then '無\n' else "符合項目"()) +
  '\n【▲不符合項目 - 必要資料未填寫】\n' +
  (if "不符合項目_必要資料未填寫"() = '' then '無\n' else "不符合項目_必要資料未填寫"()) +
  '\n【▲不符合項目 - 條件或代碼不符合】\n' +
  (if "不符合項目_條件或代碼不符合"() = '' then '無\n' else "不符合項目_條件或代碼不符合"()) +
  '\n【申請結果】\n' +
  "肝癌Lenvatinib申請結果" +
  '\n===============================================\n'
