//大腸直腸_Larotrectinib給付規定
library CRCLarotrectinibRule1 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

include CRCCodeConcept version '1.0.0' called CodeConcept

include CRCReusable version '1.0.0' called Reusable
 
context Patient


//============================================
// 主要規定一：初次使用條件
//============================================

// 本次申請紀錄（以最新一筆申請作為本次申請）
define "本次申請紀錄":
  Last(
    [MedicationRequest] MR
      where MR.intent = 'plan'
        and exists (
          MR.medication.coding Cdg
            where Cdg in CodeConcept.NHIMedication
              and Cdg.code in CodeConcept.L01EX12
        )
        and MR.dosageInstruction[0].timing.repeat.bounds is Period
      sort by FHIRHelpers.ToDateTime((dosageInstruction[0].timing.repeat.bounds as Period).start)
  )

define "本次申請起始日期":
  FHIRHelpers.ToDateTime(("本次申請紀錄".dosageInstruction[0].timing.repeat.bounds as Period).start)

define "年齡計算用申請日期":
  date from "本次申請起始日期"

define "申請日時病人年齡歲數":
  Reusable."PatientAgeInYearsAt"("年齡計算用申請日期")

define "是否滿18歲":
  Reusable."IsPatientAdultAt"("年齡計算用申請日期")


/*規則1*/
//條件1
define "1規則1-1A=NTRK基因融合且無已知的後天阻抗性突變-檢驗結果":
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

define "1規則1-1B=NTRK用藥申請":
  exists (
    [MedicationRequest] MRPlan
    where MRPlan.intent = 'plan'
    and exists (
      MRPlan.medication.coding Cdg
      where Cdg in CodeConcept.NHIMedication
      and Cdg.code in CodeConcept.L01EX12
    )
  )
  and Reusable."醫令類別為1"

define "1規則1-1=NTRK基因融合且無已知的後天阻抗性突變":
"1規則1-1A=NTRK基因融合且無已知的後天阻抗性突變-檢驗結果"
and "1規則1-1B=NTRK用藥申請"


//條件2-1-1
define "ICD代碼檢核_布林值": Reusable."主要疾病之ICD-10使用C18、C19、C20、C21"

//條件2-1-2
define "1規則1-2-1-2=三個月內有影像檢查報告":
  Reusable."HasRecentImageReport"(CodeConcept.ImageReportCode, "本次申請起始日期")

//條件2-1-3
define "1規則1-2-1-3=癌症分期分數或結果為M≠0":
  Reusable."癌症分期分數或結果為M≠0"

//條件2-1-4
define "1規則1-2-1-4=三個月內有檢查報告":
  Reusable."HasRecentDiagnosticReport"(CodeConcept.DiagnosticReportCode, "本次申請起始日期")

define "1規則1-2-1=轉移性實體腫瘤":
  Reusable."主要疾病之ICD-10使用C18、C19、C20、C21"
  and "1規則1-2-1-3=癌症分期分數或結果為M≠0"
  and ("1規則1-2-1-2=三個月內有影像檢查報告"
  or  "1規則1-2-1-4=三個月內有檢查報告")

//條件2-2-1
define "1規則1-2-2-1=存在說明手術切除極可能造成嚴重病症":
  exists (
    [Claim] C
    where exists (
      C.diagnosis Diag
      where Diag.type.text is not null
    )
  )

//條件2-2
define "1規則1-2-2=手術切除極可能造成嚴重病症":
  Reusable."主要疾病之ICD-10使用C18、C19、C20、C21"
  and "1規則1-2-2-1=存在說明手術切除極可能造成嚴重病症"
  and "1規則1-2-1-2=三個月內有影像檢查報告"

//條件3
define "1規則1-3=沒有合適的替代治療選項(包括免疫檢查點抑制劑)":
  exists (
    [Claim] C
    where exists (
      C.diagnosis Diag
      where Diag.type.text is not null
        and exists (
          Diag.type.text T
          where Matches(T, '(?i).*沒有合適的替代治療選項.*')
        )
    )
  )

define "1規則1":
  "1規則1-1=NTRK基因融合且無已知的後天阻抗性突變"
  and ("1規則1-2-1=轉移性實體腫瘤"
  or "1規則1-2-2=手術切除極可能造成嚴重病症")
  and "1規則1-3=沒有合適的替代治療選項(包括免疫檢查點抑制劑)"


/*規則3*/
//條件3-1
define "1規則3-1=檢核未滿18歲與定(符合採條件2不符合採條件3)":
  Patient.birthDate is not null
  and not "是否滿18歲"

//條件3-2
//條件3-2
define "1規則3-2=曾接受一線治療後無效或復發":
  Reusable."HasPriorMedicationUse"(CodeConcept.L01EX12, CodeConcept.L01EX12)
  and Reusable."醫令類別為1"
  and exists (
    [Claim] C
    where exists (
      C.item I
      where exists (
        I.modifier M
        where exists (
          M.coding Cdg
          where Cdg in CodeConcept.NHILOT
          and Cdg.code in { '2', '3', '4', '5' }
        )
      )
    )
  )

//條件3-3-2-1
define "1規則3-3-3-2-1=先前已使用過FOLFIRI（folinic acid/5-fluorouracil/irinotecan）":
  Reusable."HasPriorMedicationUse"(CodeConcept.L01EX12, CodeConcept.L01CE02)
  and Reusable."HasPriorMedicationUse"(CodeConcept.L01EX12, CodeConcept.L01BC02)
  and Reusable."醫令類別為1"

//條件3-3-2-2
define "1規則3-3-3-2-2=先前已使用過FOLFOX（folinic acid/5-fluorouracil/oxaliplatin）":
  Reusable."HasPriorMedicationUse"(CodeConcept.L01EX12, CodeConcept.L01BC02)
  and Reusable."HasPriorMedicationUse"(CodeConcept.L01EX12, CodeConcept.L01XA03)
  and Reusable."醫令類別為1"

define "1規則3-3-2=先前已使用過相關化學藥物治療失敗":
  "1規則3-3-3-2-1=先前已使用過FOLFIRI（folinic acid/5-fluorouracil/irinotecan）"
  or "1規則3-3-3-2-2=先前已使用過FOLFOX（folinic acid/5-fluorouracil/oxaliplatin）"

define "1規則3":
  if ("1規則3-1=檢核未滿18歲與定(符合採條件2不符合採條件3)")
  then ("1規則3-2=曾接受一線治療後無效或復發")
  else ("1規則1-2-1=轉移性實體腫瘤" and "1規則3-3-2=先前已使用過相關化學藥物治療失敗")

define "主要規定一":
  Reusable."初次申請" 
  and "1規則1" 
  and "1規則3"


//============================================
// 主要規定二：續用條件：治療持續給付
//============================================

/*規則1*/
define "2規則1=影像證據顯示病情有無惡化":
  exists (
    [MedicationRequest] MRPlan
     where MRPlan.intent = 'plan'
     and exists (
        MRPlan.medication.coding Cdg
        where Cdg in CodeConcept.NHIMedication
        and Cdg.code in CodeConcept.L01EX12
      )
  and exists (
    [DiagnosticReport] Report
     where exists (
      Report.code.coding Cdg
        where (
          Cdg in CodeConcept.ICD10PCS2023Image
          or Cdg in CodeConcept.ICD10PCS2014Image
        )
        and Cdg.code in CodeConcept.ImageReportCode
      )
      and Report.effective is not null
      and FHIRHelpers.ToDateTime(Report.effective) >= "本次申請起始日期" - 90 days
      and FHIRHelpers.ToDateTime(Report.effective) <= "本次申請起始日期"
      )
    )
  and Reusable."醫令類別為1"

define "主要規定二":
  Reusable."續用申請" and
  "2規則1=影像證據顯示病情有無惡化"


//============================================
// 主要規定三：藥品使用規則
//============================================

/*規則1*/
define "3規則1=每次申請之療程以12週為限":
  Reusable."HasMedicationPlanDurationWithin"(CodeConcept.L01EX12, 84)

define "主要規定三":
  "3規則1=每次申請之療程以12週為限"


//============================================
// 檢核結果用：必要資料存在判斷
//============================================

define "Larotrectinib申請資料存在":
  Reusable."HasMedicationPlanRecord"(CodeConcept.L01EX12)

define "NTRK檢測資料存在":
  Reusable."HasObservationCode"(CodeConcept.LarotrectinibGeneTest)

define "影像或檢查報告資料存在":
  Reusable."影像或檢查報告資料存在"

define "癌症分期資料存在":
  Reusable."癌症分期資料存在"

define "手術切除說明資料存在":
  exists (
    [DocumentReference] D
    where exists (
      D.content Content
      where Content.attachment.title is not null
    )
  )

define "替代治療說明資料存在":
  exists (
    [Claim] C
    where exists (
      C.diagnosis Diag
      where Diag.type.text is not null
    )
  )

define "先前治療資料存在":
  Reusable."HasMedicationRecord"(CodeConcept.L01BC02)
  or Reusable."HasMedicationRecord"(CodeConcept.L01XA03)
  or Reusable."HasMedicationRecord"(CodeConcept.L01CE02)

define "續用客觀證據資料存在":
  Reusable."影像或檢查報告資料存在"

define "療程期間資料存在":
  Reusable."HasMedicationPlanTiming"(CodeConcept.L01EX12)

define "必要資料皆存在":
  not (
    (Reusable."初次申請" and (
      not "Larotrectinib申請資料存在"
      or not "NTRK檢測資料存在"
      or not Reusable."主要疾病ICD診斷資料存在"
      or not "影像或檢查報告資料存在"
      or not "癌症分期資料存在"
      or not "替代治療說明資料存在"
      or Patient.birthDate is null
      or (not "是否滿18歲" and not "先前治療資料存在")
      or ("是否滿18歲" and not "先前治療資料存在")
    ))
    or (Reusable."續用申請" and (
      not "Larotrectinib申請資料存在"
      or not "續用客觀證據資料存在"
    ))
    or not "療程期間資料存在"
  )


//============================================
// 列出「符合」項目判斷式
//============================================

define function "符合項目"():
  // 主要規定一：初次使用條件
  (if Reusable."初次申請" and ("1規則1-1A=NTRK基因融合且無已知的後天阻抗性突變-檢驗結果" or "1規則1-1B=NTRK用藥申請" or Reusable."主要疾病之ICD-10使用C18、C19、C20、C21" or "1規則1-2-1-2=三個月內有影像檢查報告" or "1規則1-2-1-3=癌症分期分數或結果為M≠0" or "1規則1-2-1-4=三個月內有檢查報告" or "1規則1-2-2-1=存在說明手術切除極可能造成嚴重病症" or "1規則1-3=沒有合適的替代治療選項(包括免疫檢查點抑制劑)" or "1規則3-1=檢核未滿18歲與定(符合採條件2不符合採條件3)" or "1規則3-2=曾接受一線治療後無效或復發" or "1規則3-3-2=先前已使用過相關化學藥物治療失敗")
    then '<主要規定一：初次使用條件>\n' +
         (if "1規則1-1A=NTRK基因融合且無已知的後天阻抗性突變-檢驗結果" 
           then '● 規則1-1A：NTRK基因融合且無已知的後天阻抗性突變（檢驗結果）\n' else '') +
         (if "1規則1-1B=NTRK用藥申請" 
           then '● 規則1-1B：NTRK用藥申請\n' else '') +
         (if Reusable."主要疾病之ICD-10使用C18、C19、C20、C21"
           then '● ICD代碼檢核：主要疾病之ICD代碼為C18、C19、C20、C21\n' else '') +
         (if "1規則1-2-1=轉移性實體腫瘤"
           then '● 規則1-2-1：轉移性實體腫瘤\n' +
                (if "1規則1-2-1-2=三個月內有影像檢查報告"
                  then '  - 三個月內有影像檢查報告\n' else '') +
                (if "1規則1-2-1-3=癌症分期分數或結果為M≠0" 
                  then '  - 癌症分期為轉移性（M≠0）\n' else '') +
                (if "1規則1-2-1-4=三個月內有檢查報告"
                  then '  - 三個月內有檢查報告\n' else '')
           else '') +
         (if "1規則1-2-2=手術切除極可能造成嚴重病症"
           then '● 規則1-2-2：手術切除極可能造成嚴重病症\n' +
                (if "1規則1-2-2-1=存在說明手術切除極可能造成嚴重病症"
                  then '  - 存在說明手術切除極可能造成嚴重病症\n' else '') +
                (if "1規則1-2-1-2=三個月內有影像檢查報告"
                  then '  - 三個月內有影像檢查報告\n' else '')
           else '') +
         (if "1規則1-3=沒有合適的替代治療選項(包括免疫檢查點抑制劑)" 
           then '● 規則1-3：沒有合適的替代治療選項（包括免疫檢查點抑制劑）\n' else '') +
         (if "1規則3-1=檢核未滿18歲與定(符合採條件2不符合採條件3)"
           then '● 規則3-1：年齡未滿18歲\n' +
                (if "1規則3-2=曾接受一線治療後無效或復發"
                  then '  - 曾接受一線治療後無效或復發\n' else '')
           else '● 規則3：年齡滿18歲或以上\n' +
                (if "1規則1-2-1=轉移性實體腫瘤"
                  then '  - 轉移性實體腫瘤\n' else '') +
                (if "1規則3-3-2=先前已使用過相關化學藥物治療失敗"
                  then '  - 先前已使用過相關化學藥物治療失敗\n' else '')) +
         '\n'  
    else '') +
  
  // 主要規定二：續用條件
  (if Reusable."續用申請" and "2規則1=影像證據顯示病情有無惡化" 
    then '<主要規定二：續用條件－治療持續給付>\n' +
         '● 續用規則1：提出客觀證據（如：影像學）證實無惡化\n' +
         '\n'  
    else '') +
  
  // 主要規定三：藥品使用規則
  (if "3規則1=每次申請之療程以12週為限"
    then '<主要規定三：藥品使用規則>\n' +
         '● 規則3-1：每次申請之療程以12週為限（參考資訊）\n'
    else '')

//============================================
// 列出「不符合」項目判斷式 - 條件或代碼不符合
//============================================

define function "不符合項目_條件或代碼不符合"():
  // 主要規定一：初次使用條件 - 代碼條件不符
  (if Reusable."初次申請" and (
    ("NTRK檢測資料存在" and not "1規則1-1=NTRK基因融合且無已知的後天阻抗性突變")
    or (Reusable."主要疾病ICD診斷資料存在" and not Reusable."主要疾病之ICD-10使用C18、C19、C20、C21")
    or ("影像或檢查報告資料存在" and not ("1規則1-2-1-2=三個月內有影像檢查報告" or "1規則1-2-1-4=三個月內有檢查報告"))
    or ("癌症分期資料存在" and not "1規則1-2-1-3=癌症分期分數或結果為M≠0")
    or ("替代治療說明資料存在" and not "1規則1-3=沒有合適的替代治療選項(包括免疫檢查點抑制劑)")
    or ("先前治療資料存在" and not "1規則3")
  )
    then '<主要規定一：初次使用條件>\n' +
         (if "NTRK檢測資料存在" and not "1規則1-1=NTRK基因融合且無已知的後天阻抗性突變"
           then '▲ 規則1-1：NTRK檢測結果或用藥申請條件不符合\n' else '') +
         (if Reusable."主要疾病ICD診斷資料存在" and not Reusable."主要疾病之ICD-10使用C18、C19、C20、C21" 
           then '▲ ICD代碼檢核：主要疾病之ICD代碼未使用C18、C19、C20、C21\n' else '') +
         (if "影像或檢查報告資料存在" and not ("1規則1-2-1-2=三個月內有影像檢查報告" or "1規則1-2-1-4=三個月內有檢查報告")
           then '▲ 規則1-2-1-2/1-2-1-4：影像檢查報告或檢查報告不在三個月內或代碼不符合\n' else '') +
         (if "癌症分期資料存在" and not "1規則1-2-1-3=癌症分期分數或結果為M≠0" 
           then '▲ 癌症分期分數或結果不為M≠0\n' else '') +
         (if "替代治療說明資料存在" and not "1規則1-3=沒有合適的替代治療選項(包括免疫檢查點抑制劑)"
           then '▲ 規則1-3：替代治療選項說明不符合條件\n' else '') +
         (if "先前治療資料存在" and not "1規則3"
           then '▲ 規則3：先前治療條件不符合\n' else '') +
         '\n'  
    else '') +
  
  // 主要規定三：藥品使用規則 - 代碼條件不符
  (if "療程期間資料存在" and not "3規則1=每次申請之療程以12週為限"
    then '<主要規定三：藥品使用規則>\n' +
         '▲ 規則3-1：每次申請之療程超過12週上限（參考資訊）\n'
    else '')

//============================================
// 列出「不符合」項目判斷式 - 必要資料未填寫
//============================================

define function "不符合項目_必要資料未填寫"():
  // 主要規定一：初次使用條件 - 必要資料未填寫
  (if Reusable."初次申請" and (
    not "Larotrectinib申請資料存在"
    or not "NTRK檢測資料存在"
    or not Reusable."主要疾病ICD診斷資料存在"
    or not "影像或檢查報告資料存在"
    or not "癌症分期資料存在"
    or not "替代治療說明資料存在"
    or Patient.birthDate is null
    or not "先前治療資料存在"
  )
    then '<主要規定一:初次使用條件>\n' +
         (if not "Larotrectinib申請資料存在"
           then '▲ 申請醫令：未提供Larotrectinib申請醫令資料\n' else '') +
         (if not "NTRK檢測資料存在"
           then '▲ 規則1-1：未同時提供 NTRK 基因融合檢驗結果及 NTRK 用藥申請資料\n' else '') +
         (if not Reusable."主要疾病ICD診斷資料存在" then '▲ ICD代碼檢核：未提供主要疾病ICD診斷資料\n' else '') +
         (if not "影像或檢查報告資料存在" then '▲ 規則1-2：未提供三個月內影像檢查報告或檢查報告\n' else '') +
         (if not "癌症分期資料存在" then '▲ 規則1-2-1-3：未提供癌症分期分數或結果資料\n' else '') +
         (if not "替代治療說明資料存在"
           then '▲ 規則1-3：未說明沒有合適的替代治療選項（包括免疫檢查點抑制劑）\n' else '') +
         (if Patient.birthDate is null then '▲ 規則3：未提供出生日期，無法判定年齡條件\n' else '') +
         (if not "先前治療資料存在" then '▲ 規則3：未提供先前治療用藥資料\n' else '') +
         '\n'  
    else '') +
  
  // 主要規定二：續用條件 - 必要資料未填寫
  (if Reusable."續用申請" and (not "Larotrectinib申請資料存在" or not "續用客觀證據資料存在")
    then '<主要規定二：續用條件－治療持續給付>\n' +
         (if not "Larotrectinib申請資料存在" then '▲ 申請醫令：未提供Larotrectinib申請醫令資料\n' else '') +
         (if not "續用客觀證據資料存在" then '▲ 續用規則1：未提供客觀證據（如：影像學）\n' else '') +
         '\n'  
    else '') +

  (if not "療程期間資料存在"
    then '<主要規定三：藥品使用規則>\n' +
         '▲ 規則3-1：未提供療程起迄日期資料（參考資訊）\n' +
         '\n'
    else '')

//============================================
// 審核結果
//============================================

define "大腸直腸癌Larotrectinib申請結果_布林":
  case
    when Reusable."初次申請" then (
      "1規則1" and
      "1規則3"
    )
    when Reusable."續用申請" then (
      "2規則1=影像證據顯示病情有無惡化"
    )
    else false
  end

define "大腸直腸癌Larotrectinib申請結果":
  if (
    Reusable."初次申請" and 
    "1規則1" and
    "1規則3"
  )
  then '✓通過：初次使用－大腸直腸癌 Larotrectinib 用藥申請'
  else if (
    Reusable."續用申請" and
    "2規則1=影像證據顯示病情有無惡化"
  )
  then '✓通過：續用－大腸直腸癌 Larotrectinib 用藥申請'
  else if Reusable."初次申請"
  then '✖不通過：初次使用－大腸直腸癌 Larotrectinib 用藥申請'
  else if Reusable."續用申請"
  then '✖不通過：續用－大腸直腸癌 Larotrectinib 用藥申請'
  else '✖不通過：無法判定申請類型－大腸直腸癌 Larotrectinib 用藥申請'

//============================================
// 審核報告總結
//============================================

define "報告總結":
  '\n=== 大腸直腸癌之Larotrectinib 申請審核報告 ===\n' +
  '\n※ 備註：標示為「參考資訊」之檢核項目，係供審核參酌使用，不作為最終【申請結果】判定之依據。\n' +
  '\n【申請類型】' + Reusable."申請類型" + '\n' +
  '\n【●符合項目】\n' +
  (if "符合項目"() = '' then '無\n' else "符合項目"()) +
  '\n【▲不符合項目 - 必要資料未填寫】\n' +
  (if "不符合項目_必要資料未填寫"() = '' then '無\n' else "不符合項目_必要資料未填寫"()) +
  '\n【▲不符合項目 - 條件或代碼不符合】\n' +
  (if "不符合項目_條件或代碼不符合"() = '' then '無\n' else "不符合項目_條件或代碼不符合"()) +
  '\n【申請結果】\n' +
  "大腸直腸癌Larotrectinib申請結果" +
  '\n===============================================\n'
