//攝護腺癌_Enzalutamide給付規定-高風險非轉移性去勢抗性前列腺癌(high risk nmCRPC)
library PCEnzalutamideRule1 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

include PCCodeConcept version '1.0.0' called CodeConcept

include PCReusable version '1.0.0' called Reusable

context Patient

//============================================
// 申請紀錄
//============================================

define "本次申請紀錄":
  Reusable."LatestMedicationPlan"(CodeConcept."L02BB04")

define "本次申請起始日期":
  FHIRHelpers.ToDateTime(("本次申請紀錄".dosageInstruction[0].timing.repeat.bounds as Period).start)

define "本次申請終止日期":
  FHIRHelpers.ToDateTime(("本次申請紀錄".dosageInstruction[0].timing.repeat.bounds as Period).end)

define "ICD-C61":
Reusable."主要疾病之ICD-10使用C61"

define "M=0":
  Reusable."癌症分期分數或結果為M=0"

define "3個月內有影像檢查報告":
  Reusable."HasRecentImageReport"("本次申請起始日期", 90)

//============================================
// 主要規定一：初次使用條件
//============================================

/*規則1*/
//條件1
define "簡要病摘-非轉移性":
exists (
    [Claim] C
      where exists (
        C.diagnosis D
          where exists (
            D.type.text T
              where Matches(T.value, '(?i).*非轉移性去勢抗性前列腺癌(high risk nmCRPC).*')
          )
      )
  )

define "睪固酮達去勢標準":
  exists (
    [Observation] OBs
      where exists (
        OBs.code.coding Cdg
          where Cdg in CodeConcept.LOINC
            and Cdg.code in CodeConcept."TestosteroneCode"
      )
      and exists (
        OBs.referenceRange RR
          where RR.text is not null
            and Matches(RR.text.value, '(?i).*(<|＜)\s*50\s*ng\s*/\s*d ?l.*(<|＜)\s*1\.?7\s*nmol\s*/\s*l.*')
      )
  )

define "1規則1-1":
"ICD-C61"
and "簡要病摘-非轉移性"
and "M=0"
and "睪固酮達去勢標準"
and Reusable."續用註記為1"

//條件2
define "1規則1-2":
"本次申請起始日期" is not null
  and Patient.birthDate is not null
  and AgeInYearsAt(date from "本次申請起始日期") >= 18

define "1規則1":
"1規則1-1" and "1規則1-2"

/*規則2*/
//條件3
define "1規則2-3":
  exists ([DiagnosticReport] Report where Reusable."IsMolecularReport"(Report))

//條件4
define "1規則2-4-1":
  "本次申請起始日期" is not null
  and exists (
    [Procedure] P
    where P.status = 'completed'
      and exists (
        P.code.coding Cdg
        where (
          Cdg in CodeConcept.ICD10PCS2023Image
          or Cdg in CodeConcept.ICD10PCS2014Image
        )
        and Cdg.code in CodeConcept."SurgicalCastrationOPCode"
      )
        and P.performed is FHIR.dateTime
        and FHIRHelpers.ToDateTime(P.performed as FHIR.dateTime) < "本次申請起始日期"  
  )

define "mCRPC藥物代碼":
  CodeConcept."L02AE" union CodeConcept."L02BX02"

define "1規則2-4-2":
  exists (
    [MedicationRequest] MR
      where Reusable."HasMedicationCode"(MR, "mCRPC藥物代碼")
        and Reusable."HasValidTiming"(MR)
        and Reusable."GetEndTime"(MR) < "本次申請終止日期"
        and (duration in months between Reusable."GetEndTime"(MR) and "本次申請終止日期") <= 6
  )

define "1規則2-4":
"1規則2-4-1" or "1規則2-4-2"

//條件5
define "1規則2-5":
  exists (
    [Observation] OBs
      where exists (
        OBs.code.coding Cdg
          where Cdg in CodeConcept.LOINC
            and Cdg.code in CodeConcept."TestosteroneCode"
      )
  )

//條件6
define "1規則2-6":
"3個月內有影像檢查報告"
and "M=0"

define "1規則2":
"1規則2-3" and "1規則2-4" and "1規則2-5" and "1規則2-6"

/*規則3*/
define "1規則3":
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
              and Cdg.code in CodeConcept.ECOG
        )
        and (
          (OBs.value is FHIR.integer and (OBs.value as FHIR.integer).value <= 1)
          or (OBs.value is FHIR.Quantity and (OBs.value as FHIR.Quantity).value <= 1)
          or (OBs.value is FHIR.string and Matches((OBs.value as FHIR.string).value, '(?i).*(<=1).*'))
        )
  )

/*規則4*/
define "1規則4":
  exists (
    [Observation] OBs
      where exists (
        OBs.code.coding Cdg
          where Cdg in CodeConcept.LOINC
            and Cdg.code in CodeConcept."PSACode"
      )
  )

/*規則5*/
//條件9
define "1規則5-9":
"1規則4"

//條件10
define "1規則5-10":
"1規則4"

//條件11
define "1規則5-11":
"1規則4"

define "1規則5":
"1規則5-9" and "1規則5-10" and "1規則5-11"

define "主要規定一":
"本次申請紀錄" is not null
and "1規則1" and "1規則2" and "1規則3" and "1規則4" and "1規則5"

//============================================
// 主要規定二：續用條件
//============================================

/*規則1*/
//條件1
define "2規則1-1":
Reusable."續用註記為2"

//條件2
define "2規則1-2":
Reusable."HasRecentImageReport"("本次申請起始日期", 180)
and "1規則4"

define "2規則1":
"2規則1-1" and "2規則1-2"

define "主要規定二":
"本次申請紀錄" is not null
and "2規則1-1" and "2規則1-2"

//============================================
// 主要規定三：藥品使用規則
//============================================

/*規則1*/
//條件1
define "化療前曾使用Enzalutamide":
  exists (
    [MedicationRequest] Chemo
      where Reusable."HasMedicationCode"(Chemo, CodeConcept."L01CD")
        and Reusable."HasValidTiming"(Chemo)
        and Reusable."GetEndTime"(Chemo) < "本次申請起始日期"
        and exists (
          [MedicationRequest] PriorEnza
            where Reusable."HasMedicationCode"(PriorEnza, CodeConcept."L02BB04")
              and Reusable."HasValidTiming"(PriorEnza)
              and Reusable."GetEndTime"(PriorEnza) <= Reusable."GetStartTime"(Chemo)
        )
  )

define "3規則1-1":
    not "化療前曾使用Enzalutamide"

/*規則2*/
//條件2
define "3規則2-2-1":
not exists (
    [MedicationRequest] MR
      where Reusable."HasMedicationCode"(MR, CodeConcept."EnzalutamideExcludedConcurrentMedication")
        and Reusable."HasValidTiming"(MR)
  )

define "3規則2-2-2":
exists (
    [Claim] C
      where exists (
        C.diagnosis D
          where exists (
            D.type.text T
              where Matches(T.value, '(?i).*嚴重不耐受反應導致必須永久停止治療.*')
          )
      )
  )

define "3規則2-2":
  if "3規則2-2-1" then true
  else "3規則2-2-2"  

/*規則3*/
//事前審查藥物(Enzalutamide)預定處方起始日期(useSdate)
define "useSdate":
  "本次申請起始日期"

//事前審查藥物(Enzalutamide)預定處方終止日期(useEdate)
define "useEdate":
  "本次申請終止日期"

define "3規則3-3":
  not exists (
    [MedicationRequest] MR
      where Reusable."HasMedicationCode"(MR, CodeConcept."V10XX03")
        and Reusable."HasValidTiming"(MR)
        and "useSdate" <= Reusable."GetEndTime"(MR)
        and "useEdate" >= Reusable."GetStartTime"(MR)
  )

define "主要規定三":
"本次申請紀錄" is not null
and "3規則1-1" and "3規則2-2" and "3規則3-3"

//============================================
// 檢核結果用：必要資料存在判斷
//============================================

define "Enzalutamide申請資料存在":
  Reusable."HasMedicationPlanRecord"(CodeConcept."L02BB04")

define "療程期間資料存在":
  Reusable."HasMedicationPlanTiming"(CodeConcept."L02BB04")

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

define "睪固酮檢驗資料存在":
  exists (
    [Observation] OBs
      where exists (
        OBs.code.coding Cdg
          where Cdg in CodeConcept.LOINC
            and Cdg.code in CodeConcept."TestosteroneCode"
      )
  )

define "分子檢查報告資料存在":
  exists (
    [DiagnosticReport] Report
      where Reusable."IsMolecularReport"(Report)
  )

define "影像檢查報告資料存在":
  exists (
    [DiagnosticReport] Report
      where Reusable."IsImageReport"(Report)
  )

define "手術去勢處置資料存在":
  exists (
    [Procedure] P
      where P.status = 'completed'
        and exists (
          P.code.coding Cdg
            where (
              Cdg in CodeConcept.ICD10PCS2023Image
              or Cdg in CodeConcept.ICD10PCS2014Image
            )
            and Cdg.code in CodeConcept."SurgicalCastrationOPCode"
        )
  )

define "去勢用藥處方資料存在":
  exists (
    [MedicationRequest] MR
      where Reusable."HasMedicationCode"(MR, "mCRPC藥物代碼")
  )

define "ECOG資料存在":
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
              and Cdg.code in CodeConcept.ECOG
        )
  )

define "PSA檢驗資料存在":
  exists (
    [Observation] OBs
      where exists (
        OBs.code.coding Cdg
          where Cdg in CodeConcept.LOINC
            and Cdg.code in CodeConcept."PSACode"
      )
  )

define "化療藥物處方資料存在":
  exists (
    [MedicationRequest] MR
      where Reusable."HasMedicationCode"(MR, CodeConcept."L01CD")
  )

define "不得併用藥物處方資料存在":
  exists (
    [MedicationRequest] MR
      where Reusable."HasMedicationCode"(MR, CodeConcept."EnzalutamideExcludedConcurrentMedication")
  )

define "V10XX03處方資料存在":
  exists (
    [MedicationRequest] MR
      where Reusable."HasMedicationCode"(MR, CodeConcept."V10XX03")
  )

define "必要資料皆存在":
  not (
    (
      Reusable."初次申請" and (
        not "Enzalutamide申請資料存在"
        or not "攝護腺癌ICD診斷資料存在"
        or not "簡要病摘資料存在"
        or not "癌症分期資料存在"
        or not "睪固酮檢驗資料存在"
        or not "分子檢查報告資料存在"
        or (not "手術去勢處置資料存在" and not "去勢用藥處方資料存在")
        or not "影像檢查報告資料存在"
        or not "ECOG資料存在"
        or not "PSA檢驗資料存在"
        or Patient.birthDate is null
      )
    )
    or (
      Reusable."續用申請" and (
        not "Enzalutamide申請資料存在"
        or not "影像檢查報告資料存在"
        or not "PSA檢驗資料存在"
      )
    )
    or not "療程期間資料存在"
  )

//============================================
// 列出「符合」項目判斷式
//============================================

define function "符合項目"():
  // 主要規定一：初次使用條件
  (if Reusable."初次申請" and "主要規定一"
    then '<主要規定一：初次使用條件>\n' +
         (if "1規則1" then '● 規則1：符合ICD-C61、簡要病摘（非轉移性去勢抗性前列腺癌）、癌症分期M=0、睪固酮達去勢標準及續用註記為1之初次使用條件\n' else '') +
         (if "1規則2" then '● 規則2：符合分子檢查報告、手術去勢或mCRPC治療藥物6個月內終止、睪固酮檢驗及3個月內影像檢查報告與M=0之條件\n' else '') +
         (if "1規則3" then '● 規則3：符合ECOG評估≦1之條件\n' else '') +
         (if "1規則4" then '● 規則4：符合PSA檢驗代碼之條件\n' else '') +
         (if "1規則5" then '● 規則5：符合PSA檢驗代碼之條件\n' else '') +
         '\n'
    else '') +

  // 主要規定二：續用條件
  (if Reusable."續用申請" and "主要規定二"
    then '<主要規定二：續用條件>\n' +
         (if "2規則1" then '● 規則1：符合續用註記為2、180天內影像檢查報告及PSA檢驗之續用條件\n' else '') +
         '\n'
    else '') +

  // 主要規定三：藥品使用規則
  (if ("3規則1-1" or "3規則2-2" or "3規則3-3")
    then '<主要規定三：藥品使用規則>\n' +
         (if "3規則1-1" then '● 規則1：化療前未曾使用Enzalutamide，或該次使用已因嚴重不耐受反應而永久停止治療（參考資訊）\n' else '') +
         (if "3規則2-2" then '● 規則2：未合併使用不得併用藥物，或已因嚴重不耐受反應永久停止治療（參考資訊）\n' else '') +
         (if "3規則3-3" then '● 規則3：本次申請期間未合併使用Radium-223（V10XX03）藥品（參考資訊）\n' else '') +
         '\n'
    else '')

//============================================
// 列出「不符合」項目判斷式 - 條件或代碼不符合
//============================================

define function "不符合項目_條件或代碼不符合"():
  // 主要規定一：初次使用條件 - 已提供資料但條件或代碼不符合
  (if Reusable."初次申請" and (
      (("攝護腺癌ICD診斷資料存在" and "簡要病摘資料存在") and not "1規則1")
      or ("分子檢查報告資料存在" and not "1規則2")
      or ("ECOG資料存在" and not "1規則3")
      or ("PSA檢驗資料存在" and not "1規則4")
      or ("PSA檢驗資料存在" and not "1規則5")
    )
    then '<主要規定一：初次使用條件>\n' +
         (if ("攝護腺癌ICD診斷資料存在" and "簡要病摘資料存在") and not "1規則1" then '▲ 規則1：ICD代碼、簡要病摘、癌症分期或睪固酮檢驗結果不符合初次使用條件\n' else '') +
         (if "分子檢查報告資料存在" and not "1規則2" then '▲ 規則2：分子檢查報告、手術去勢或mCRPC治療藥物終止時間、睪固酮檢驗或影像檢查報告不符合初次使用條件\n' else '') +
         (if "ECOG資料存在" and not "1規則3" then '▲ 規則3：ECOG評估結果不符合≦1之條件\n' else '') +
         (if "PSA檢驗資料存在" and not "1規則4" then '▲ 規則4：PSA檢驗代碼不符合條件\n' else '') +
         (if "PSA檢驗資料存在" and not "1規則5" then '▲ 規則5：PSA檢驗代碼不符合條件\n' else '') +
         '\n'
    else '') +

  // 主要規定二：續用條件 - 已提供資料但條件或代碼不符合
  (if Reusable."續用申請" and (("影像檢查報告資料存在" and "PSA檢驗資料存在") and not "2規則1")
    then '<主要規定二：續用條件>\n' +
         '▲ 規則1：續用註記、180天內影像檢查報告或PSA檢驗不符合續用條件\n' +
         '\n'
    else '') +

  // 主要規定三：藥品使用規則 - 已提供資料但條件或代碼不符合
  (if (("化療藥物處方資料存在" and not "3規則1-1")
      or ("不得併用藥物處方資料存在" and not "3規則2-2")
      or ("V10XX03處方資料存在" and not "3規則3-3")
    )
    then '<主要規定三：藥品使用規則>\n' +
         (if "化療藥物處方資料存在" and not "3規則1-1" then '▲ 規則1：化療前已使用Enzalutamide，且非因嚴重不耐受反應而永久停止治療（參考資訊）\n' else '') +
         (if "不得併用藥物處方資料存在" and not "3規則2-2" then '▲ 規則2：合併使用不得併用藥物，且非因嚴重不耐受反應永久停止治療（參考資訊）\n' else '') +
         (if "V10XX03處方資料存在" and not "3規則3-3" then '▲ 規則3：本次申請期間合併使用Radium-223（V10XX03）藥品（參考資訊）\n' else '') +
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
      not "Enzalutamide申請資料存在"
      or not "攝護腺癌ICD診斷資料存在"
      or not "簡要病摘資料存在"
      or not "癌症分期資料存在"
      or not "睪固酮檢驗資料存在"
      or not "分子檢查報告資料存在"
      or (not "手術去勢處置資料存在" and not "去勢用藥處方資料存在")
      or not "影像檢查報告資料存在"
      or not "ECOG資料存在"
      or not "PSA檢驗資料存在"
      or Patient.birthDate is null
    )
    then '<主要規定一：初次使用條件>\n' +
         (if not "Enzalutamide申請資料存在" then '▲ 申請醫令：未提供Enzalutamide申請醫令資料\n' else '') +
         (if not "攝護腺癌ICD診斷資料存在" then '▲ 規則1：未提供主要疾病ICD診斷資料\n' else '') +
         (if not "簡要病摘資料存在" then '▲ 規則1：未提供簡要病摘資料\n' else '') +
         (if not "癌症分期資料存在" then '▲ 規則1/2：未提供癌症分期資料\n' else '') +
         (if not "睪固酮檢驗資料存在" then '▲ 規則1/2：未提供睪固酮檢驗資料\n' else '') +
         (if not "分子檢查報告資料存在" then '▲ 規則2：未提供分子檢查報告資料\n' else '') +
         (if not "手術去勢處置資料存在" and not "去勢用藥處方資料存在" then '▲ 規則2：未提供手術去勢處置或去勢用藥處方資料\n' else '') +
         (if not "影像檢查報告資料存在" then '▲ 規則2：未提供影像檢查報告資料\n' else '') +
         (if not "ECOG資料存在" then '▲ 規則3：未提供ECOG評估資料\n' else '') +
         (if not "PSA檢驗資料存在" then '▲ 規則4/5：未提供PSA檢驗資料\n' else '') +
         (if Patient.birthDate is null then '▲ 規則1：未提供出生日期資料\n' else '') +
         '\n'
    else '') +

  // 主要規定二：續用條件 - 必要資料未填寫
  (if Reusable."續用申請" and (
      not "Enzalutamide申請資料存在"
      or not "影像檢查報告資料存在"
      or not "PSA檢驗資料存在"
    )
    then '<主要規定二：續用條件>\n' +
         (if not "Enzalutamide申請資料存在" then '▲ 申請醫令：未提供Enzalutamide申請醫令資料\n' else '') +
         (if not "影像檢查報告資料存在" then '▲ 規則1：未提供影像檢查報告資料\n' else '') +
         (if not "PSA檢驗資料存在" then '▲ 規則1：未提供PSA檢驗資料\n' else '') +
         '\n'
    else '') +

  // 主要規定三：藥品使用規則 - 必要資料未填寫
  (if not "療程期間資料存在"
    then '<主要規定三：藥品使用規則>\n' +
         '▲ 規則1/2/3：未提供療程起迄日期資料（參考資訊）\n' +
         '\n'
    else '')

//============================================
// 審核結果
//============================================

define "攝護腺癌Enzalutamide申請結果_布林":
  case
    when Reusable."初次申請" then "主要規定一"
    when Reusable."續用申請" then "主要規定二"
    else false
  end

define "攝護腺癌Enzalutamide申請結果":
  if Reusable."初次申請" and "攝護腺癌Enzalutamide申請結果_布林"
  then '✓通過：初次使用－攝護腺癌 Enzalutamide 用藥申請'
  else if Reusable."續用申請" and "攝護腺癌Enzalutamide申請結果_布林"
  then '✓通過：續用－攝護腺癌 Enzalutamide 用藥申請'
  else if Reusable."初次申請"
  then '✖不通過：初次使用－攝護腺癌 Enzalutamide 用藥申請'
  else if Reusable."續用申請"
  then '✖不通過：續用－攝護腺癌 Enzalutamide 用藥申請'
  else '✖不通過：無法判定申請類型－攝護腺癌 Enzalutamide 用藥申請'

//============================================
// 審核報告總結
//============================================

define "報告總結":
  '\n=== 攝護腺癌之Enzalutamide 申請審核報告 ===\n' +
  '\n※ 備註：標示為「參考資訊」之檢核項目，係供審核參酌使用，不作為最終【申請結果】判定之依據。\n' +
  '\n【申請類型】' + Reusable."申請類型" + '\n' +
  '\n【●符合項目】\n' +
  (if "符合項目"() = '' then '無\n' else "符合項目"()) +
  '\n【▲不符合項目 - 必要資料未填寫】\n' +
  (if "不符合項目_必要資料未填寫"() = '' then '無\n' else "不符合項目_必要資料未填寫"()) +
  '\n【▲不符合項目 - 條件或代碼不符合】\n' +
  (if "不符合項目_條件或代碼不符合"() = '' then '無\n' else "不符合項目_條件或代碼不符合"()) +
  '\n【申請結果】\n' +
  "攝護腺癌Enzalutamide申請結果" +
  '\n===============================================\n'