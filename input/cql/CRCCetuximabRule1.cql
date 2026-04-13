//大腸直腸_Cetuximab給付規定
library CRCCetuximabRule1 version '1.0.0'

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
        and MR.dosageInstruction[0].timing.repeat.bounds is Period
      sort by FHIRHelpers.ToDateTime((dosageInstruction[0].timing.repeat.bounds as Period).start)
  )

define "本次申請起始日期":
  FHIRHelpers.ToDateTime(("本次申請紀錄".dosageInstruction[0].timing.repeat.bounds as Period).start)




/*規則1*/
//條件1
//條件1
define "規則1-1=初次使用Cetuximab與FOLFIRI（Folinic acid/ 5-fluorouracil/irinotecan）合併使用":
  Reusable."HasConcurrentMedicationOrders2"(CodeConcept.L01FE01, CodeConcept.L01BC02, CodeConcept.L01CE02)
  and Reusable."醫令類別為1"


//條件2
define "規則1-2=初次使用Cetuximab與FOLFOX(Folinic acid/ 5-fluorouracil/oxaliplatin)合併使用":
  Reusable."HasConcurrentMedicationOrders2"(CodeConcept.L01FE01, CodeConcept.L01BC02, CodeConcept.L01XA03)
  and Reusable."醫令類別為1"



//條件3
define "規則1-3=用於治療具表皮生長因子受體表現型(EGFR expressing)":
  exists (
    [Observation] RasObs
    where RasObs.status = 'final'
    and exists (
      RasObs.code.coding Cdg
      where Cdg.code = '69548-6'
      and Cdg in CodeConcept.LOINC
    )
    and exists (
      RasObs.component C
      where exists (
        C.code.coding Cdg
        where Cdg.code in CodeConcept.GeneTestEGFRexpressing
      )
      and C.value is not null
      and C.value is FHIR.string
      and Matches((C.value as FHIR.string).value, '(?i).*(positive|detected|present|expressed|overexpressed|amplified|\\+).*')
    )
  )

define "規則1":
  (("規則1-1=初次使用Cetuximab與FOLFIRI（Folinic acid/ 5-fluorouracil/irinotecan）合併使用"
  or "規則1-2=初次使用Cetuximab與FOLFOX(Folinic acid/ 5-fluorouracil/oxaliplatin)合併使用")
  and "規則1-3=用於治療具表皮生長因子受體表現型(EGFR expressing)")

/*規則2*/
//條件1
define "規則2-1=K-ras為原生型(wild type)" :
  exists (
    [Observation] RasObs
    where RasObs.status = 'final'
    and exists (
      RasObs.code.coding Cdg
      where Cdg.code = '69548-6'
      and Cdg in CodeConcept.LOINC
    )
    and exists (
      RasObs.component C
      where exists (
        C.code.coding Cdg
        where Cdg.code in CodeConcept.GeneTest
      )
    )
    and exists (
      RasObs.interpretation.coding I
      where I.code = 'NEG'
    )
  )

//條件2-1
//Reusable."主要疾病之主要疾病之主要疾病之ICD-10使用C18、C19、C20、C21"
define "ICD代碼檢核_布林值": Reusable."主要疾病之ICD-10使用C18、C19、C20、C21"

//條件2-2
define "規則2-2-2=三個月內有影像檢查報告":
  exists (
    [DiagnosticReport] O
    where exists (
      O.code.coding Cdg
      where (
        Cdg in CodeConcept.ICD10PCS2023Image
        or Cdg in CodeConcept.ICD10PCS2014Image
      )
      and Cdg.code in CodeConcept.CetuximabRegorafenibImageReportCode
    )
    and O.effective is not null
    and FHIRHelpers.ToDateTime(O.effective) >= "本次申請起始日期" - 90 days
    and FHIRHelpers.ToDateTime(O.effective) <= "本次申請起始日期"
  )

//條件2-3
define "規則2-2-3=癌症分期分數或結果為M≠0":
  Count(
    [Observation] O
    where exists (
    O.code.coding Cdg
    where Cdg.code = '399390009'
    and Cdg in CodeConcept.SNOMED
    )
    and O.value is not null
    and O.value is FHIR.string
    and Matches((O.value as FHIR.string).value, '.*M[1-9].*')
  ) > 0

//條件2-4
define "規則2-2-4=用藥線別為第一線":
  exists (
    [Claim] C
      where exists (
        C.item I
          where exists (
            I.modifier M
              where exists (
                M.coding Cdg
                  where Cdg in CodeConcept.NHILOT
                    and Cdg.code = '1'
              )
          )
      )
  )

define "規則2=轉移性直腸結腸癌病患之第一線治療":
  Reusable."主要疾病之ICD-10使用C18、C19、C20、C21"
  and "規則2-2-2=三個月內有影像檢查報告"
  and "規則2-2-3=癌症分期分數或結果為M≠0"
  and "規則2-2-4=用藥線別為第一線"

define "主要規定一":
  Reusable."初次申請" and
  "規則1"
  and "規則2-1=K-ras為原生型(wild type)"
  and "規則2=轉移性直腸結腸癌病患之第一線治療"


//============================================
// 主要規定二：續用條件－治療持續給付
//============================================

/*規則1*/
define "規則1=提出客觀證據（如：影像學）證實無惡化，才可繼續使用":
  exists (
    [MedicationRequest] MRPlan
     where MRPlan.intent = 'plan'
     and exists (
        MRPlan.medication.coding Cdg
        where Cdg in CodeConcept.NHIMedication
        and Cdg.code in CodeConcept.L01FE01
      )
  and exists (
    [DiagnosticReport] Report
     where exists (
      Report.code.coding Cdg
        where (
          Cdg in CodeConcept.ICD10PCS2023Image
          or Cdg in CodeConcept.ICD10PCS2014Image
        )
        and Cdg.code in CodeConcept.CetuximabRegorafenibImageReportCode
      )
      and Report.effective is not null
      and FHIRHelpers.ToDateTime(Report.effective) >= "本次申請起始日期" - 90 days
      and FHIRHelpers.ToDateTime(Report.effective) <= "本次申請起始日期"
      )
    )
  and Reusable."醫令類別為1"

define "主要規定二":
  Reusable."續用申請" and
  "規則1=提出客觀證據（如：影像學）證實無惡化，才可繼續使用"


//============================================
// 主要規定三：藥品使用規則
//============================================

/*規則1*/
//條件1
define "規則1-1=Panitumumab與cetuximab二者僅能擇一使用":
  not (
    Reusable."HasMedicationUse"(CodeConcept.L01FE02)
    and Reusable."HasMedicationUse"(CodeConcept.L01FE01)
  )

//條件2
define "規則1-2=無法忍受化療(其副作用)時(有註記)":
  exists (
    [Claim] C
    where exists (
      C.diagnosis D
      where D.type.text contains '無法忍受副作用'
    )
  )

//條件3
define "規則1-3=Panitumumab與Cetuximab使用時間不重疊":
  not Reusable."HasMedicationPeriodsOverlap"(CodeConcept.L01FE02, CodeConcept.L01FE01)
  
//條件4
define "規則1-4=每次申請事前審查之療程以18週為限":
  Reusable."HasMedicationPlanDurationWithin"(CodeConcept.L01FE01, 126)

//條件5
define "規則1-5=二者使用總療程併計算,以全部36週為上限(Panitumumab與cetuximab)":
  Reusable."HasMedicationTotalDurationWithin"(CodeConcept.L01FE, 252)

define "3規則1":
("規則1-2=無法忍受化療(其副作用)時(有註記)" and "規則1-3=Panitumumab與Cetuximab使用時間不重疊")//情況1: 有「無法忍受化療副作用」註記時，允許互換使用兩種藥物，但使用時間不可重疊
or
(not "規則1-2=無法忍受化療(其副作用)時(有註記)" and "規則1-1=Panitumumab與cetuximab二者僅能擇一使用")//情況2: 沒有「無法忍受化療副作用」註記時，二者僅能擇一使用（只能有其中一種藥物的使用記錄）
and "規則1-4=每次申請事前審查之療程以18週為限"
and "規則1-5=二者使用總療程併計算,以全部36週為上限(Panitumumab與cetuximab)"

/*規則2*/
//條件1
define "規則2-1=未使用bevacizumab藥品":
  not Reusable."HasMedicationUse"(CodeConcept.L01FG01)

//條件2
define "規則2-2=本藥品未與bevacizumab併用":
  not Reusable."HasConcurrentMedicationPlan"(CodeConcept.L01FE01, CodeConcept.L01FG01)

define "規則2":
  "規則2-1=未使用bevacizumab藥品"
  or "規則2-2=本藥品未與bevacizumab併用"

define "主要規定三":
  "3規則1" and "規則2"


//============================================
// 列出「符合」項目判斷式
//============================================

define function "符合項目"():
  // 主要規定一：初次使用條件
  (if Reusable."初次申請" and ("規則1" or "規則2-1=K-ras為原生型(wild type)" or "規則2-2-2=三個月內有影像檢查報告" or "規則2-2-3=癌症分期分數或結果為M≠0" or "規則2-2-4=用藥線別為第一線")
    then '<主要規定一：初次使用條件>\n' +
         (if "規則1-1=初次使用Cetuximab與FOLFIRI（Folinic acid/ 5-fluorouracil/irinotecan）合併使用" 
           then '● 規則1-1：Cetuximab與FOLFIRI（Folinic acid/5-fluorouracil/irinotecan）合併使用\n' else '') +
         (if "規則1-2=初次使用Cetuximab與FOLFOX(Folinic acid/ 5-fluorouracil/oxaliplatin)合併使用" 
           then '● 規則1-2：Cetuximab與FOLFOX（Folinic acid/5-fluorouracil/oxaliplatin）合併使用\n' else '') +
         (if "規則1-3=用於治療具表皮生長因子受體表現型(EGFR expressing)" 
           then '● 規則1-3：用於治療具表皮生長因子受體表現型（EGFR expressing）\n' else '') +
         (if "規則2-1=K-ras為原生型(wild type)" 
           then '● 規則2-1：K-ras為原生型（wild type）\n' else '') +
         (if Reusable."主要疾病之ICD-10使用C18、C19、C20、C21" 
           then '● 規則2-2-1：主要疾病之ICD代碼為C18、C19、C20、C21\n' else '') +
         (if "規則2-2-2=三個月內有影像檢查報告"
           then '● 規則2-2-2：三個月內有影像檢查報告\n' else '') +
         (if "規則2-2-3=癌症分期分數或結果為M≠0" 
           then '● 規則2-2-3：癌症分期為轉移性（M≠0）\n' else '') +
         (if "規則2-2-4=用藥線別為第一線" 
           then '● 規則2-2-4：用藥線別為第一線\n' else '') +
         '\n'  
    else '') +
  
  // 主要規定二：續用條件
  (if Reusable."續用申請" and "規則1=提出客觀證據（如：影像學）證實無惡化，才可繼續使用" 
    then '<主要規定二：續用條件－治療持續給付>\n' +
         '● 續用規則1：提出客觀證據（如：影像學）證實無惡化\n' +
         '\n'  
    else '') +
  
  // 主要規定三：藥品使用規則
  (if "規則1-1=Panitumumab與cetuximab二者僅能擇一使用" or "規則1-2=無法忍受化療(其副作用)時(有註記)" or "規則1-3=Panitumumab與Cetuximab使用時間不重疊" or "規則1-4=每次申請事前審查之療程以18週為限" or "規則1-5=二者使用總療程併計算,以全部36週為上限(Panitumumab與cetuximab)" or "規則2-1=未使用bevacizumab藥品" or "規則2-2=本藥品未與bevacizumab併用"
    then '<主要規定三：藥品使用規則>\n' +
         (if "規則1-2=無法忍受化療(其副作用)時(有註記)" and "規則1-3=Panitumumab與Cetuximab使用時間不重疊"
           then '● 規則3-1-1：有「無法忍受化療副作用」註記，且Panitumumab與Cetuximab使用時間不重疊\n' 
           else if not "規則1-2=無法忍受化療(其副作用)時(有註記)" and "規則1-1=Panitumumab與cetuximab二者僅能擇一使用"
           then '● 規則3-1-2：Panitumumab與cetuximab二者僅擇一使用\n'
           else '') +
         (if "規則1-4=每次申請事前審查之療程以18週為限" 
           then '● 規則3-1-3：每次申請事前審查之療程以18週為限\n' else '') +
         (if "規則1-5=二者使用總療程併計算,以全部36週為上限(Panitumumab與cetuximab)" 
           then '● 規則3-1-4：Panitumumab與cetuximab使用總療程併計算，以全部36週為上限\n' else '') +
         (if "規則2-1=未使用bevacizumab藥品" 
           then '● 規則3-2-1：未使用bevacizumab藥品\n' else '') +
         (if "規則2-2=本藥品未與bevacizumab併用" 
           then '● 規則3-2-2：本藥品未與bevacizumab併用\n' else '')
    else '')

//============================================
// 列出「不符合」項目判斷式 - 代碼或條件不符
//============================================

define function "不符合項目_代碼或條件不符"():
  // 主要規定一：初次使用條件 - 代碼條件不符
  (if Reusable."初次申請" and (not "規則2-1=K-ras為原生型(wild type)" or not Reusable."主要疾病之ICD-10使用C18、C19、C20、C21" or not "規則2-2-3=癌症分期分數或結果為M≠0" or not "規則2-2-4=用藥線別為第一線")
    then '<主要規定一：初次使用條件>\n' +
         (if not "規則2-1=K-ras為原生型(wild type)" 
           then '▲ 規則2-1：K-ras非原生型或未提供檢測結果\n' else '') +
         (if not Reusable."主要疾病之ICD-10使用C18、C19、C20、C21" 
           then '▲ 規則2-2-1：主要疾病之ICD代碼未使用C18、C19、C20、C21\n' else '') +
         (if not "規則2-2-3=癌症分期分數或結果為M≠0" 
           then '▲ 規則2-2-3：癌症分期分數或結果不為M≠0\n' else '') +
         (if not "規則2-2-4=用藥線別為第一線" 
           then '▲ 規則2-2-4：用藥線別不為第一線\n' else '') +
         '\n'  
    else '') +
  
  // 主要規定三：藥品使用規則 - 代碼條件不符
  (if not "3規則1" or not "規則2"
    then '<主要規定三：藥品使用規則>\n' +
         (if not "3規則1"
           then '▲ 規則3-1：Panitumumab與cetuximab使用規定不符\n' +
                (if "規則1-2=無法忍受化療(其副作用)時(有註記)" and not "規則1-3=Panitumumab與Cetuximab使用時間不重疊"
                  then '  （有「無法忍受化療副作用」註記，但Panitumumab與Cetuximab使用時間重疊）\n'
                  else if not "規則1-2=無法忍受化療(其副作用)時(有註記)" and not "規則1-1=Panitumumab與cetuximab二者僅能擇一使用"
                  then '  （無「無法忍受化療副作用」註記，但二者同時使用）\n'
                  else '')
           else '') +
         (if not "規則1-4=每次申請事前審查之療程以18週為限" 
           then '▲ 規則3-1-3：每次申請事前審查之療程超過18週上限\n' else '') +
         (if not "規則1-5=二者使用總療程併計算,以全部36週為上限(Panitumumab與cetuximab)" 
           then '▲ 規則3-1-4：Panitumumab與cetuximab使用總療程超過36週上限\n' else '') +
         (if not ("規則2-1=未使用bevacizumab藥品" or "規則2-2=本藥品未與bevacizumab併用")
           then '▲ 規則3-2：因與bevacizumab併用，故不符合本藥品之使用規則\n' else '')
    else '')

//============================================
// 列出「不符合」項目判斷式 - 必要資料未填寫
//============================================

define function "不符合項目_必要資料未填寫"():
  // 主要規定一：初次使用條件 - 必要資料未填寫
  (if Reusable."初次申請" and (not "規則1" or not "規則2-2-2=三個月內有影像檢查報告")
    then '<主要規定一：初次使用條件>\n' +
         (if not "規則1"
           then '▲ 規則1：未提供化學療法併用資料或EGFR表現型檢測結果\n' +
                (if not ("規則1-1=初次使用Cetuximab與FOLFIRI（Folinic acid/ 5-fluorouracil/irinotecan）合併使用" or "規則1-2=初次使用Cetuximab與FOLFOX(Folinic acid/ 5-fluorouracil/oxaliplatin)合併使用")
                  then '  （需有FOLFIRI或FOLFOX之處方）\n' else '') +
                (if not "規則1-3=用於治療具表皮生長因子受體表現型(EGFR expressing)"
                  then '  （需提供EGFR expressing檢測結果）\n' else '')
           else '') +
         (if not "規則2-2-2=三個月內有影像檢查報告"
           then '▲ 規則2-2-2：未提供三個月內影像檢查報告\n' else '') +
         '\n'  
    else '') +
  
  // 主要規定二：續用條件 - 必要資料未填寫
  (if Reusable."續用申請" and not "規則1=提出客觀證據（如：影像學）證實無惡化，才可繼續使用"
    then '<主要規定二：續用條件－治療持續給付>\n' +
         '▲ 續用規則1：未提供客觀證據（如：影像學）\n' +
         '\n'  
    else '')

//============================================
// 審核結果
//============================================

define "大腸直腸癌Cetuximab第一線治療申請結果_布林":
  case
    when Reusable."初次申請" then (
      "規則1" and
      "規則2-1=K-ras為原生型(wild type)" and
      "規則2=轉移性直腸結腸癌病患之第一線治療" and
      "3規則1" and  
      "規則2"
    )
    when Reusable."續用申請" then (
      "規則1=提出客觀證據（如：影像學）證實無惡化，才可繼續使用" and
      "3規則1" and  
      "規則2"
    )
    else false
  end


define "大腸直腸癌Cetuximab第一線治療申請結果":
  if (
    Reusable."初次申請" and 
    "規則1" and
    "規則2-1=K-ras為原生型(wild type)" and
    "規則2=轉移性直腸結腸癌病患之第一線治療" and
    "3規則1" and  
    "規則2"
  )
  then '✓通過：初次使用－大腸直腸癌 Cetuximab 第一線用藥申請'
  else if (
    Reusable."續用申請" and
    "規則1=提出客觀證據（如：影像學）證實無惡化，才可繼續使用" and
    "3規則1" and  
    "規則2"
  )
  then '✓通過：續用－大腸直腸癌 Cetuximab 第一線用藥申請'
  else if Reusable."初次申請"
  then '✖不通過：初次使用－大腸直腸癌 Cetuximab 第一線用藥申請'
  else if Reusable."續用申請"
  then '✖不通過：續用－大腸直腸癌 Cetuximab 第一線用藥申請'
  else '✖不通過：無法判定申請類型－大腸直腸癌 Cetuximab 第一線用藥申請'


//============================================
// 審核報告總結
//============================================

define "報告總結":
  '\n=== 大腸直腸癌之Cetuximab(一線治療) 申請審核報告 ===\n' +
  '\n【申請類型】' + Reusable."申請類型" + '\n' +
  '\n【●符合項目】\n' +
  (if "符合項目"() = '' then '無\n' else "符合項目"()) +
  '\n【▲不符合項目 - 代碼或條件不符】\n' +
  (if "不符合項目_代碼或條件不符"() = '' then '無\n' else "不符合項目_代碼或條件不符"()) +
  '\n【▲不符合項目 - 必要資料未填寫】\n' +
  (if "不符合項目_必要資料未填寫"() = '' then '無\n' else "不符合項目_必要資料未填寫"()) +
  '\n【申請結果】\n' +
  "大腸直腸癌Cetuximab第一線治療申請結果" +
  '\n===============================================\n'
