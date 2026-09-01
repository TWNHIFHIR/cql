//攝護腺癌_Radium-223給付規定
library PCRadium223Rule1 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

include PCCodeConcept version '1.0.0' called CodeConcept

include PCReusable version '1.0.0' called Reusable

context Patient


//============================================
// 申請紀錄
//============================================

// 本次申請紀錄（以最新一筆 Radium-223 申請作為本次申請）
define "本次申請紀錄":
  Reusable."LatestMedicationPlan"(CodeConcept."V10XX03")

define "本次申請起始日期":
  FHIRHelpers.ToDateTime(("本次申請紀錄".dosageInstruction[0].timing.repeat.bounds as Period).start)

define "本次申請終止日期":
  FHIRHelpers.ToDateTime(("本次申請紀錄".dosageInstruction[0].timing.repeat.bounds as Period).end)


//============================================
// 主要規定一：初次使用條件
//============================================

/*規則1*/
//條件1-1
define "1規則1-1-1=主要疾病之ICD代碼為C61":
  Reusable."主要疾病之ICD-10使用C61"

//條件1-2
define "1規則1-1-2=手術去勢":
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

//條件1-3
define "1規則1-1-3=藥物去勢":
  Reusable."HasPriorMedicationUse"(CodeConcept."V10XX03", CodeConcept."MedicalCastration")

//條件1-4
define "1規則1-1-4=有檢查報告":
  "本次申請起始日期" is not null
  and exists (
    [DiagnosticReport] O2
    where exists (
      O2.code.coding Cdg
      where Cdg in CodeConcept.LOINC
        and Cdg.code = '66117-3'
    )
      and O2.effective is not null
      and FHIRHelpers.ToDateTime(O2.effective) <= "本次申請起始日期"
  )

//條件1-5
define "1規則1-1-5=檢驗檢查":
  exists (
    [Observation] OBs
      where exists (
        OBs.category C
          where exists (
            C.coding Cdg
              where Cdg in CodeConcept.NHIPASSupportingInfoType
                and Cdg.code = 'tests'
          )
      )
        and exists (
          OBs.code.coding Cdg
          where Cdg in CodeConcept.LOINC
            and Cdg.code in CodeConcept."Radium223LabTestCode"
        )
  )

//條件1
define "1規則1-1=限用於治療去勢抗性攝護腺癌":
  "1規則1-1-1=主要疾病之ICD代碼為C61"
  and ("1規則1-1-2=手術去勢" or "1規則1-1-3=藥物去勢")
  and "1規則1-1-4=有檢查報告"
  and "1規則1-1-5=檢驗檢查"

//條件2-1
define "1規則1-2-1=癌症分期分數或結果為M≠0":
  Reusable."癌症分期分數或結果為M≠0"

//條件2-2
define "1規則1-2-2=三個月內有轉移相關影像報告":
  Reusable."HasRecentImageReportWithCodes"(CodeConcept."Radium223MetastasisImageReportCode", "本次申請起始日期", 90)

//條件2-3
define "1規則1-2-3=影像報告證明遠端轉移只有骨轉移且無臟器轉移":
  exists (
    [DiagnosticReport] Report
    where exists (
      Report.code.coding Cdg
      where (
        Cdg in CodeConcept.ICD10PCS2023Image
        or Cdg in CodeConcept.ICD10PCS2014Image
        or Cdg in CodeConcept.NHIMedication
      )
      and Cdg.code in CodeConcept."Radium223NoVisceralMetastasisImageReportCode"
    )
      and Reusable."IsReportWithinDaysBefore"(Report, "本次申請起始日期", 90)
      and Report.conclusion is not null
      and Matches(Report.conclusion.value, '(?i).*(遠端轉移只有骨轉移).*')
  )

define "1規則1-2=合併有症狀的骨轉移且尚未有臟器轉移":
  "1規則1-2-1=癌症分期分數或結果為M≠0"
  and "1規則1-2-2=三個月內有轉移相關影像報告"
  and "1規則1-2-3=影像報告證明遠端轉移只有骨轉移且無臟器轉移"

define "1規則1=限用於治療去勢抗性攝護腺癌且合併有症狀的骨轉移尚未有臟器轉移者":
  "1規則1-1=限用於治療去勢抗性攝護腺癌"
  and "1規則1-2=合併有症狀的骨轉移且尚未有臟器轉移"


/*規則2*/
//條件3
define "1規則2-1=三個月內影像報告證明骨轉移≧2處":
  exists (
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
      and Reusable."IsReportWithinDaysBefore"(Report, "本次申請起始日期", 90)
      and Report.conclusion is not null
      and Matches(Report.conclusion.value, '(?i).*(骨轉移.{0,20}(≧|>=|大於等於|至少)?[2-9]處|[2-9]處.{0,20}骨轉移|兩處.{0,20}骨轉移|多處.{0,20}骨轉移|multiple.{0,20}bone).*')
  )

define "1規則2=患者須合併有症狀之骨轉移且骨轉移≧2處":
  "1規則2-1=三個月內影像報告證明骨轉移≧2處"


/*規則3*/
//條件7
define "1規則3-1=用藥紀錄證明有症狀骨轉移需常規使用止痛藥物":
  Reusable."HasConcurrentMedicationOrderWithinPlan"(CodeConcept."V10XX03", CodeConcept."Radium223Analgesic")

//條件8
define "1規則3-2=三個月內影像報告證明無臟器轉移":
  "1規則1-2-3=影像報告證明遠端轉移只有骨轉移且無臟器轉移"

define "1規則3=申請時檢附用藥紀錄及三個月內影像報告":
  "1規則3-1=用藥紀錄證明有症狀骨轉移需常規使用止痛藥物"
  and "1規則2-1=三個月內影像報告證明骨轉移≧2處"
  and "1規則3-2=三個月內影像報告證明無臟器轉移"

define "主要規定一":
  Reusable."初次申請"
  and Reusable."醫令類別為1"
  and "1規則1=限用於治療去勢抗性攝護腺癌且合併有症狀的骨轉移尚未有臟器轉移者"
  and "1規則2=患者須合併有症狀之骨轉移且骨轉移≧2處"
  and "1規則3=申請時檢附用藥紀錄及三個月內影像報告"


//============================================
// 主要規定三：藥品使用規則
//============================================

/*規則1*/
define "3規則1-1=每位患者最高使用六個療程":
  Reusable."HasMedicationTotalDurationWithin"(CodeConcept."V10XX03", 180)

/*規則2*/
define "3規則2-1=有不得併用藥物":
  Reusable."HasConcurrentMedicationUse"(CodeConcept."V10XX03", CodeConcept."Radium223ContraindicatedConcurrentMedication")

define "3規則2=不得合併使用abiraterone、enzalutamide及其他治療因惡性腫瘤伴隨骨骼事件之藥品":
  not "3規則2-1=有不得併用藥物"

define "主要規定三":
  "3規則1-1=每位患者最高使用六個療程"
  and "3規則2=不得合併使用abiraterone、enzalutamide及其他治療因惡性腫瘤伴隨骨骼事件之藥品"


//============================================
// 檢核結果用：必要資料存在判斷
//============================================

define "Radium223申請資料存在":
  Reusable."HasMedicationPlanRecord"(CodeConcept."V10XX03")

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
  Reusable."HasMedicationPlanTiming"(CodeConcept."V10XX03")

define "攝護腺癌ICD診斷資料存在":
  Reusable."主要疾病ICD診斷資料存在"

define "去勢治療資料存在":
  "1規則1-1-2=手術去勢"
  or Reusable."HasMedicationRecord"(CodeConcept."MedicalCastration")

define "檢查報告資料存在":
  exists (
    [DiagnosticReport] O2
    where exists (
      O2.code.coding Cdg
      where Cdg in CodeConcept.LOINC
        and Cdg.code = '66117-3'
    )
      and O2.effective is not null
  )

define "檢驗檢查資料存在":
  exists (
    [Observation] OBs
      where exists (
        OBs.category C
          where exists (
            C.coding Cdg
              where Cdg in CodeConcept.NHIPASSupportingInfoType
                and Cdg.code = 'tests'
          )
      )
        and exists (
          OBs.code.coding Cdg
          where Cdg in CodeConcept.LOINC
        )
  )

define "癌症分期資料存在":
  Reusable."癌症分期資料存在"

define "影像報告資料存在":
  Reusable."HasRecentImageReportWithCodes"(CodeConcept."Radium223MetastasisImageReportCode", "本次申請起始日期", 90)

define "止痛藥用藥資料存在":
  Reusable."HasMedicationRecord"(CodeConcept."Radium223Analgesic")

define "必要資料皆存在":
  not (
    (
      Reusable."初次申請" and (
        not "Radium223申請資料存在"
        or not "醫令類別資料存在"
        or not "攝護腺癌ICD診斷資料存在"
        or not "去勢治療資料存在"
        or not "檢查報告資料存在"
        or not "檢驗檢查資料存在"
        or not "癌症分期資料存在"
        or not "影像報告資料存在"
        or not "止痛藥用藥資料存在"
      )
    )
    or (
      Reusable."續用申請" and (
        not "Radium223申請資料存在"
      )
    )
    or not "療程期間資料存在"
  )


//============================================
// 列出「符合」項目判斷式
//============================================

define function "符合項目"():
  // 主要規定一：初次使用條件
  (if Reusable."初次申請" and (Reusable."醫令類別為1" or "1規則1-1-1=主要疾病之ICD代碼為C61" or "1規則1-1-2=手術去勢" or "1規則1-1-3=藥物去勢" or "1規則1-1-4=有檢查報告" or "1規則1-1-5=檢驗檢查" or "1規則1-2-1=癌症分期分數或結果為M≠0" or "1規則1-2-2=三個月內有轉移相關影像報告" or "1規則1-2-3=影像報告證明遠端轉移只有骨轉移且無臟器轉移" or "1規則2-1=三個月內影像報告證明骨轉移≧2處" or "1規則3-1=用藥紀錄證明有症狀骨轉移需常規使用止痛藥物")
    then '<主要規定一：初次使用條件>\n' +
         (if Reusable."醫令類別為1" then '● 申請醫令：醫令類別為1\n' else '') +
         (if "1規則1-1-1=主要疾病之ICD代碼為C61" then '● 規則1-1-1：主要疾病之ICD代碼為C61\n' else '') +
         (if "1規則1-1-2=手術去勢" then '● 規則1-1-2：已完成手術去勢\n' else '') +
         (if "1規則1-1-3=藥物去勢" then '● 規則1-1-3：已有藥物去勢用藥紀錄\n' else '') +
         (if "1規則1-1-4=有檢查報告" then '● 規則1-1-4：有LOINC 66117-3檢查報告\n' else '') +
         (if "1規則1-1-5=檢驗檢查" then '● 規則1-1-5：有指定LOINC檢驗檢查資料\n' else '') +
         (if "1規則1-2-1=癌症分期分數或結果為M≠0" then '● 規則1-2-1：癌症分期分數或結果為M≠0\n' else '') +
         (if "1規則1-2-2=三個月內有轉移相關影像報告" then '● 規則1-2-2：三個月內有轉移相關影像報告\n' else '') +
         (if "1規則1-2-3=影像報告證明遠端轉移只有骨轉移且無臟器轉移" then '● 規則1-2-3：影像報告證明遠端轉移只有骨轉移且無臟器轉移\n' else '') +
         (if "1規則2-1=三個月內影像報告證明骨轉移≧2處" then '● 規則2-1：三個月內影像報告證明骨轉移≧2處\n' else '') +
         (if "1規則3-1=用藥紀錄證明有症狀骨轉移需常規使用止痛藥物" then '● 規則3-1：用藥紀錄證明需常規使用止痛藥物\n' else '') +
         '\n'
    else '') +

  // 主要規定三：藥品使用規則
  (if "3規則1-1=每位患者最高使用六個療程" or "3規則2=不得合併使用abiraterone、enzalutamide及其他治療因惡性腫瘤伴隨骨骼事件之藥品"
    then '<主要規定三：藥品使用規則>\n' +
         (if "3規則1-1=每位患者最高使用六個療程" then '● 規則3-1：每位患者最高使用六個療程（參考資訊）\n' else '') +
         (if "3規則2=不得合併使用abiraterone、enzalutamide及其他治療因惡性腫瘤伴隨骨骼事件之藥品" then '● 規則3-2：未合併使用不得併用藥物（參考資訊）\n' else '') +
         '\n'
    else '')

//============================================
// 列出「不符合」項目判斷式 - 條件或代碼不符合
//============================================

define function "不符合項目_條件或代碼不符合"():
  // 主要規定一：初次使用條件 - 已提供資料但條件或代碼不符合
  (if Reusable."初次申請" and (
      ("醫令類別資料存在" and not Reusable."醫令類別為1")
      or ("攝護腺癌ICD診斷資料存在" and not "1規則1-1-1=主要疾病之ICD代碼為C61")
      or ("去勢治療資料存在" and not ("1規則1-1-2=手術去勢" or "1規則1-1-3=藥物去勢"))
      or ("檢查報告資料存在" and not "1規則1-1-4=有檢查報告")
      or ("檢驗檢查資料存在" and not "1規則1-1-5=檢驗檢查")
      or ("癌症分期資料存在" and not "1規則1-2-1=癌症分期分數或結果為M≠0")
      or ("影像報告資料存在" and not "1規則1-2-3=影像報告證明遠端轉移只有骨轉移且無臟器轉移")
      or ("影像報告資料存在" and not "1規則2-1=三個月內影像報告證明骨轉移≧2處")
      or ("止痛藥用藥資料存在" and not "1規則3-1=用藥紀錄證明有症狀骨轉移需常規使用止痛藥物")
    )
    then '<主要規定一：初次使用條件>\n' +
         (if "醫令類別資料存在" and not Reusable."醫令類別為1" then '▲ 申請醫令：醫令類別不為1\n' else '') +
         (if "攝護腺癌ICD診斷資料存在" and not "1規則1-1-1=主要疾病之ICD代碼為C61" then '▲ 規則1-1-1：主要疾病之ICD代碼未使用C61\n' else '') +
         (if "去勢治療資料存在" and not ("1規則1-1-2=手術去勢" or "1規則1-1-3=藥物去勢") then '▲ 規則1-1-2/3：去勢治療資料不符合本次申請日前使用條件\n' else '') +
         (if "檢查報告資料存在" and not "1規則1-1-4=有檢查報告" then '▲ 規則1-1-4：LOINC 66117-3檢查報告日期晚於本次申請起始日\n' else '') +
         (if "檢驗檢查資料存在" and not "1規則1-1-5=檢驗檢查" then '▲ 規則1-1-5：檢驗檢查LOINC代碼不符合指定清單\n' else '') +
         (if "癌症分期資料存在" and not "1規則1-2-1=癌症分期分數或結果為M≠0" then '▲ 規則1-2-1：癌症分期分數或結果不為M≠0\n' else '') +
         (if "影像報告資料存在" and not "1規則1-2-3=影像報告證明遠端轉移只有骨轉移且無臟器轉移" then '▲ 規則1-2-3：影像報告未證明遠端轉移只有骨轉移\n' else '') +
         (if "影像報告資料存在" and not "1規則2-1=三個月內影像報告證明骨轉移≧2處" then '▲ 規則2-1：影像報告未證明骨轉移≧2處\n' else '') +
         (if "止痛藥用藥資料存在" and not "1規則3-1=用藥紀錄證明有症狀骨轉移需常規使用止痛藥物" then '▲ 規則3-1：止痛藥用藥紀錄未涵蓋本次申請療程期間\n' else '') +
         '\n'
    else '') +

  // 主要規定三：藥品使用規則 - 已提供資料但條件或代碼不符合
  (if "療程期間資料存在" and (not "3規則1-1=每位患者最高使用六個療程" or not "3規則2=不得合併使用abiraterone、enzalutamide及其他治療因惡性腫瘤伴隨骨骼事件之藥品")
    then '<主要規定三：藥品使用規則>\n' +
         (if not "3規則1-1=每位患者最高使用六個療程" then '▲ 規則3-1：Radium-223總療程超過180天（六個療程）（參考資訊）\n' else '') +
         (if not "3規則2=不得合併使用abiraterone、enzalutamide及其他治療因惡性腫瘤伴隨骨骼事件之藥品" then '▲ 規則3-2：本次申請期間合併使用不得併用藥物（參考資訊）\n' else '') +
         '\n'
    else '')

//============================================
// 列出「不符合」項目判斷式 - 必要資料未填寫
//============================================

define function "不符合項目_必要資料未填寫"():
  // 主要規定一：初次使用條件 - 必要資料未填寫
  (if Reusable."初次申請" and (
      not "Radium223申請資料存在"
      or not "醫令類別資料存在"
      or not "攝護腺癌ICD診斷資料存在"
      or not "去勢治療資料存在"
      or not "檢查報告資料存在"
      or not "檢驗檢查資料存在"
      or not "癌症分期資料存在"
      or not "影像報告資料存在"
      or not "止痛藥用藥資料存在"
    )
    then '<主要規定一：初次使用條件>\n' +
         (if not "Radium223申請資料存在" then '▲ 申請醫令：未提供Radium-223申請醫令資料\n' else '') +
         (if not "醫令類別資料存在" then '▲ 申請醫令：未提供醫令類別資料\n' else '') +
         (if not "攝護腺癌ICD診斷資料存在" then '▲ 規則1-1-1：未提供主要疾病ICD診斷資料\n' else '') +
         (if not "去勢治療資料存在" then '▲ 規則1-1-2/3：未提供手術去勢或藥物去勢資料\n' else '') +
         (if not "檢查報告資料存在" then '▲ 規則1-1-4：未提供LOINC 66117-3檢查報告\n' else '') +
         (if not "檢驗檢查資料存在" then '▲ 規則1-1-5：未提供檢驗檢查資料\n' else '') +
         (if not "癌症分期資料存在" then '▲ 規則1-2-1：未提供癌症分期分數或結果資料\n' else '') +
         (if not "影像報告資料存在" then '▲ 規則1-2/2-1：未提供三個月內影像報告資料\n' else '') +
         (if not "止痛藥用藥資料存在" then '▲ 規則3-1：未提供常規止痛藥用藥紀錄\n' else '') +
         '\n'
    else '') +

  // 主要規定二：續用條件 - 必要資料未填寫
  (if Reusable."續用申請" and (
      not "Radium223申請資料存在"
    )
    then '<主要規定二：續用條件－治療持續給付>\n' +
         (if not "Radium223申請資料存在" then '▲ 申請醫令：未提供Radium-223申請醫令資料\n' else '') +
         '\n'
    else '') +

  // 主要規定三：藥品使用規則 - 必要資料未填寫
  (if not "療程期間資料存在"
    then '<主要規定三：藥品使用規則>\n' +
         '▲ 規則3-1：未提供療程起迄日期資料（參考資訊）\n' +
         '\n'
    else '')

//============================================
// 審核結果
//============================================

define "攝護腺癌Radium223申請結果_布林":
  case
    when Reusable."初次申請" then (
      "主要規定一"
    )
    else false
  end

define "攝護腺癌Radium223申請結果":
  if (
    Reusable."初次申請" and
    "主要規定一"
  )
  then '✓通過：初次使用－攝護腺癌 Radium-223 用藥申請'
  else if Reusable."初次申請"
  then '✖不通過：初次使用－攝護腺癌 Radium-223 用藥申請'
  else if Reusable."續用申請"
  then '✖不通過：續用－攝護腺癌 Radium-223 用藥申請（本頁籤未列續用條件）'
  else '✖不通過：無法判定申請類型－攝護腺癌 Radium-223 用藥申請'

//============================================
// 審核報告總結
//============================================

define "報告總結":
  '\n=== 攝護腺癌之Radium-223 申請審核報告 ===\n' +
  '\n※ 備註：標示為「參考資訊」之檢核項目，係供審核參酌使用，不作為最終【申請結果】判定之依據。\n' +
  '\n【申請類型】' + Reusable."申請類型" + '\n' +
  '\n【●符合項目】\n' +
  (if "符合項目"() = '' then '無\n' else "符合項目"()) +
  '\n【▲不符合項目 - 必要資料未填寫】\n' +
  (if "不符合項目_必要資料未填寫"() = '' then '無\n' else "不符合項目_必要資料未填寫"()) +
  '\n【▲不符合項目 - 條件或代碼不符合】\n' +
  (if "不符合項目_條件或代碼不符合"() = '' then '無\n' else "不符合項目_條件或代碼不符合"()) +
  '\n【申請結果】\n' +
  "攝護腺癌Radium223申請結果" +
  '\n===============================================\n'

