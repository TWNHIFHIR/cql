//大腸直腸_Panitumumab給付規定
library CRCPanitumumabRule1 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

include CRCCodeConcept version '1.0.0' called CodeConcept

include CRCReusable version '1.0.0' called Reusable
 
context Patient

//============================================
// 申請類型判斷
//============================================

define "初次申請":
  "申請類型" = '初次使用'

define "續用申請":
  "申請類型" = '續用'

define "申請類型未知":
  "申請類型" = '無法判斷申請類型'

define "申請類型":
  case
    when Reusable."續用註記為1" then '初次使用'
    when Reusable."續用註記為2" then '續用'
    else '無法判斷申請類型'
  end


//============================================
// 主要規定一：初次使用條件
//============================================

/*規則1*/
//條件1
define "規則1-1=初次使用Panitumumab需與FOLFOX(folinicacid/5-fluorouracil/oxaliplatin)合併使用":
  (
    // 存在 Fluorouracil 處方
    exists (
      [MedicationRequest] MROrder1
      where MROrder1.intent = 'order'
      and exists (
        MROrder1.medication.coding Cdg
        where Cdg in CodeConcept.NHIMedication
        and Cdg.code in CodeConcept.L01BC02
      )
      and Reusable."HasValidTiming"(MROrder1)
    )
    and
    // 存在 Oxaliplatin 處方  
    exists (
      [MedicationRequest] MROrder2
      where MROrder2.intent = 'order'
      and exists (
        MROrder2.medication.coding Cdg
        where Cdg in CodeConcept.NHIMedication
        and Cdg.code in CodeConcept.L01XA03
      )
      and Reusable."HasValidTiming"(MROrder2)
    )
    and
    // Panitumumab 申請
    exists (
      [MedicationRequest] MRPlan
      where MRPlan.intent = 'plan'
      and exists (
        MRPlan.medication.coding Cdg
        where Cdg in CodeConcept.NHIMedication
        and Cdg.code in CodeConcept.L01FE02
      )
    )
  )
  and Reusable."醫令類別為1"

//條件2
define "規則1-2=初次使用Panitumumab與FOLFIRI(folinic acid/ 5-fluorouracil/irinotecan)合併使用":
  (
    // 存在 Fluorouracil 處方
    exists (
      [MedicationRequest] MROrder1
      where MROrder1.intent = 'order'
      and exists (
        MROrder1.medication.coding Cdg
        where Cdg in CodeConcept.NHIMedication
        and Cdg.code in CodeConcept.L01BC02
      )
      and Reusable."HasValidTiming"(MROrder1)
    )
    and
    // 存在 Irinotecan 處方  
    exists (
      [MedicationRequest] MROrder2
      where MROrder2.intent = 'order'
      and exists (
        MROrder2.medication.coding Cdg
        where Cdg in CodeConcept.NHIMedication
        and Cdg.code in CodeConcept.L01CE02
      )
      and Reusable."HasValidTiming"(MROrder2)
    )
    and
    // Panitumumab 申請
    exists (
      [MedicationRequest] MRPlan
      where MRPlan.intent = 'plan'
      and exists (
        MRPlan.medication.coding Cdg
        where Cdg in CodeConcept.NHIMedication
        and Cdg.code in CodeConcept.L01FE02
      )
    )
  )
  and Reusable."醫令類別為1"

define "規則1":
  "規則1-1=初次使用Panitumumab需與FOLFOX(folinicacid/5-fluorouracil/oxaliplatin)合併使用"
  or "規則1-2=初次使用Panitumumab與FOLFIRI(folinic acid/ 5-fluorouracil/irinotecan)合併使用"

/*規則2*/
define "規則2=K-RAS基因及N-RAS基因沒有突變":
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

/*規則3*/
//條件1
//Reusable."ICD-10使用C18、C19、C20、C21"
define "ICD代碼檢核_布林值": Reusable."主要疾病之ICD-10使用C18、C19、C20、C21"

//條件2
define "規則3-2=三個月內有影像檢查報告":
  exists (
    [DiagnosticReport] O
    where exists (
      O.code.coding Cdg
      where (
        Cdg in CodeConcept.ICD10PCS2023Image
        or Cdg in CodeConcept.ICD10PCS2014Image
      )
      and Cdg.code in CodeConcept.ImageReportCode
    )
    and O.effective is not null
    and FHIRHelpers.ToDateTime(O.effective) >= Today() - 90 days
    and FHIRHelpers.ToDateTime(O.effective) <= Today()
  )

//條件3
define "規則3-3=癌症分期分數或結果為M>=1":
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

//條件4
define "規則3-4=三個月內有檢查報告":
  exists (
    [DiagnosticReport] O2
    where exists (
      O2.code.coding Cdg
      where Cdg in CodeConcept.LOINC
      and Cdg.code in CodeConcept.DiagnosticReport
    )
    and O2.effective is not null
    and FHIRHelpers.ToDateTime(O2.effective) >= Today() - 90 days
    and FHIRHelpers.ToDateTime(O2.effective) <= Today()
  ) 

//條件5
define "規則3-5=用藥線別為第一線":
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

define "規則3":
  Reusable."主要疾病之ICD-10使用C18、C19、C20、C21"
  and ("規則3-2=三個月內有影像檢查報告" or "規則3-4=三個月內有檢查報告")
  and "規則3-3=癌症分期分數或結果為M>=1"
  and "規則3-5=用藥線別為第一線"


define "主要規定一":
  "初次申請" and
  "規則1"
  and "規則2=K-RAS基因及N-RAS基因沒有突變"
  and "規則3"



//============================================
// 主要規定二：續用條件－治療持續給付
//============================================

/*規則1*/
define "規則1=再次申請必須提出客觀證據(如：影像學)證實無惡化，才可繼續使用":
  exists (
    [MedicationRequest] MRPlan
     where MRPlan.intent = 'plan'
     and exists (
        MRPlan.medication.coding Cdg
        where Cdg in CodeConcept.NHIMedication
        and Cdg.code in CodeConcept.L01FE02
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
      and FHIRHelpers.ToDateTime(Report.effective) >= Today() - 90 days
      and FHIRHelpers.ToDateTime(Report.effective) <= Today()
      )
    )
  and Reusable."醫令類別為1"

define "主要規定二":
  "續用申請" and
  "規則1=再次申請必須提出客觀證據(如：影像學)證實無惡化，才可繼續使用"


//============================================
// 主要規定三：藥品使用規則
//============================================

/*規則1*/
//條件1
define "規則1-1=Panitumumab與Cetuximab二者僅能擇一使用":
  not (
    exists (
      [MedicationRequest] M1
      where exists (
        M1.medication.coding Cdg1
        where Cdg1.code in CodeConcept.L01FE02
      )
      and Reusable."HasValidTiming"(M1)
    )
    and
    exists (
      [MedicationRequest] M2
      where exists (
        M2.medication.coding Cdg2
        where Cdg2.code in CodeConcept.L01FE01
      )
      and Reusable."HasValidTiming"(M2)
    )
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
  not (
    exists (
      [MedicationRequest] M1
      where 
        exists (
          M1.medication.coding Cdg1
          where Cdg1 in CodeConcept.NHIMedication
          and Cdg1.code in CodeConcept.L01FE02
        )
        and Reusable."HasValidTiming"(M1)
        and M1.dosageInstruction[0].timing.repeat.bounds is Period
        and (start of (M1.dosageInstruction[0].timing.repeat.bounds as Period)) is not null
        and (end of (M1.dosageInstruction[0].timing.repeat.bounds as Period)) is not null
    )
    and exists (
      [MedicationRequest] M2
      where 
        exists (
          M2.medication.coding Cdg2
          where Cdg2 in CodeConcept.NHIMedication
          and Cdg2.code in CodeConcept.L01FE01
        )
        and Reusable."HasValidTiming"(M2)
        and M2.dosageInstruction[0].timing.repeat.bounds is Period
        and (start of (M2.dosageInstruction[0].timing.repeat.bounds as Period)) is not null
        and (end of (M2.dosageInstruction[0].timing.repeat.bounds as Period)) is not null
        
        and exists (
          [MedicationRequest] M1_inner
          where 
            exists (
              M1_inner.medication.coding Cdg1_inner
              where Cdg1_inner in CodeConcept.NHIMedication
              and Cdg1_inner.code in CodeConcept.L01FE02
            )
            and Reusable."HasValidTiming"(M1_inner)
            and M1_inner.dosageInstruction[0].timing.repeat.bounds is Period
            and (start of (M1_inner.dosageInstruction[0].timing.repeat.bounds as Period)) is not null
            and (end of (M1_inner.dosageInstruction[0].timing.repeat.bounds as Period)) is not null
            
            and (
              (end of (M1_inner.dosageInstruction[0].timing.repeat.bounds as Period)) >= 
              (start of (M2.dosageInstruction[0].timing.repeat.bounds as Period))
              and
              (end of (M2.dosageInstruction[0].timing.repeat.bounds as Period)) >= 
              (start of (M1_inner.dosageInstruction[0].timing.repeat.bounds as Period))
            )
        )
    )
  )

//條件4
define "規則1-4=每次申請事前審查之療程以18週為限":
  exists [MedicationRequest] MRPlan
  where MRPlan.intent = 'plan'
  and exists (
      MRPlan.medication.coding Cdg
      where Cdg in CodeConcept.NHIMedication
  )
  and days between
      start of (MRPlan.dosageInstruction[0].timing.repeat.bounds as Period)
      and
      end of (MRPlan.dosageInstruction[0].timing.repeat.bounds as Period)
        <= 126

define "3規則1":
  (
    ("規則1-2=無法忍受化療(其副作用)時(有註記)" and "規則1-3=Panitumumab與Cetuximab使用時間不重疊")
    or
    (not "規則1-2=無法忍受化療(其副作用)時(有註記)" and "規則1-1=Panitumumab與Cetuximab二者僅能擇一使用")
  )
  and "規則1-4=每次申請事前審查之療程以18週為限"

/*規則2*/
//條件1
define "規則2-1=未使用Bevacizumab藥品":
  not exists (
    [MedicationRequest] M
    where exists (
      M.medication.coding Cdg
      where Cdg in CodeConcept.NHIMedication
      and Cdg.code in CodeConcept.L01FG01
    )
    and Reusable."HasValidTiming"(M)
  )

//條件2
define "規則2-2=本藥品未與Bevacizumab併用":
  exists (
    [MedicationRequest] MRmed
    where MRmed.intent = 'plan'
    and exists (
      MRmed.medication.coding Cdg
      where Cdg in CodeConcept.NHIMedication
      and Cdg.code in CodeConcept.L01FE02
    )
    and exists MRmed.dosageInstruction
    and MRmed.dosageInstruction[0].timing.repeat.bounds is Period
    and (start of (MRmed.dosageInstruction[0].timing.repeat.bounds as Period)) is not null
    and (end of (MRmed.dosageInstruction[0].timing.repeat.bounds as Period)) is not null
    and not exists (
      [MedicationRequest] M
      where M.intent = 'plan'
      and exists (
        M.medication.coding Cdg
        where Cdg in CodeConcept.NHIMedication
        and (Cdg.code in CodeConcept.L01FG01)
      )
      and exists M.dosageInstruction
      and M.dosageInstruction[0].timing.repeat.bounds is Period
      and (start of (M.dosageInstruction[0].timing.repeat.bounds as Period)) is not null
      and (end of (M.dosageInstruction[0].timing.repeat.bounds as Period)) is not null
      and (start of (M.dosageInstruction[0].timing.repeat.bounds as Period)) <= 
          (end of (MRmed.dosageInstruction[0].timing.repeat.bounds as Period))
      and (end of (M.dosageInstruction[0].timing.repeat.bounds as Period)) >= 
          (start of (MRmed.dosageInstruction[0].timing.repeat.bounds as Period))
    )
  )

define "規則2":
  "規則2-1=未使用Bevacizumab藥品"
  or "規則2-2=本藥品未與Bevacizumab併用"

define "主要規定三":
  "3規則1" and "規則2"


//============================================
// 列出「符合」項目判斷式
//============================================

define function "符合項目"():
  // 主要規定一：初次使用條件
  (if "初次申請" and ("規則1" or "規則2=K-RAS基因及N-RAS基因沒有突變" or "規則3-2=三個月內有影像檢查報告" or "規則3-3=癌症分期分數或結果為M>=1" or "規則3-4=三個月內有檢查報告" or "規則3-5=用藥線別為第一線")
    then '<主要規定一：初次使用條件>\n' +
         (if "規則1-1=初次使用Panitumumab需與FOLFOX(folinicacid/5-fluorouracil/oxaliplatin)合併使用" 
           then '● 規則1-1：Panitumumab與FOLFOX（folinic acid/5-fluorouracil/oxaliplatin）合併使用\n' else '') +
         (if "規則1-2=初次使用Panitumumab與FOLFIRI(folinic acid/ 5-fluorouracil/irinotecan)合併使用" 
           then '● 規則1-2：Panitumumab與FOLFIRI（folinic acid/5-fluorouracil/irinotecan）合併使用\n' else '') +
         (if "規則2=K-RAS基因及N-RAS基因沒有突變" 
           then '● 規則2：K-RAS基因及N-RAS基因沒有突變\n' else '') +
         (if Reusable."主要疾病之ICD-10使用C18、C19、C20、C21" 
           then '● 規則3-1：主要疾病之ICD代碼為C18、C19、C20、C21\n' else '') +
         (if "規則3-2=三個月內有影像檢查報告"
           then '● 規則3-2：三個月內有影像檢查報告\n' else '') +
         (if "規則3-3=癌症分期分數或結果為M>=1" 
           then '● 規則3-3：癌症分期為轉移性（M≥1）\n' else '') +
         (if "規則3-4=三個月內有檢查報告"
           then '● 規則3-4：三個月內有檢查報告\n' else '') +
         (if "規則3-5=用藥線別為第一線" 
           then '● 規則3-5：用藥線別為第一線\n' else '') +
         '\n'  
    else '') +
  
  // 主要規定二：續用條件
  (if "續用申請" and "規則1=再次申請必須提出客觀證據(如：影像學)證實無惡化，才可繼續使用" 
    then '<主要規定二：續用條件－治療持續給付>\n' +
         '● 續用規則1：提出客觀證據（如：影像學）證實無惡化\n' +
         '\n'  
    else '') +
  
  // 主要規定三：藥品使用規則
  (if "規則1-1=Panitumumab與Cetuximab二者僅能擇一使用" or "規則1-2=無法忍受化療(其副作用)時(有註記)" or "規則1-3=Panitumumab與Cetuximab使用時間不重疊" or "規則1-4=每次申請事前審查之療程以18週為限" or "規則2-1=未使用Bevacizumab藥品" or "規則2-2=本藥品未與Bevacizumab併用"
    then '<主要規定三：藥品使用規則>\n' +
         (if "規則1-2=無法忍受化療(其副作用)時(有註記)" and "規則1-3=Panitumumab與Cetuximab使用時間不重疊"
           then '● 規則3-1-1：有「無法忍受化療副作用」註記，且Panitumumab與Cetuximab使用時間不重疊\n' 
           else if not "規則1-2=無法忍受化療(其副作用)時(有註記)" and "規則1-1=Panitumumab與Cetuximab二者僅能擇一使用"
           then '● 規則3-1-2：Panitumumab與Cetuximab二者僅擇一使用\n'
           else '') +
         (if "規則1-4=每次申請事前審查之療程以18週為限" 
           then '● 規則3-1-3：每次申請事前審查之療程以18週為限\n' else '') +
         (if "規則2-1=未使用Bevacizumab藥品" 
           then '● 規則3-2-1：未使用Bevacizumab藥品\n' else '') +
         (if "規則2-2=本藥品未與Bevacizumab併用" 
           then '● 規則3-2-2：本藥品未與Bevacizumab併用\n' else '')
    else '')

//============================================
// 列出「不符合」項目判斷式 - 代碼或條件不符
//============================================

define function "不符合項目_代碼或條件不符"():
  // 主要規定一：初次使用條件 - 代碼條件不符
  (if "初次申請" and (not "規則2=K-RAS基因及N-RAS基因沒有突變" or not Reusable."主要疾病之ICD-10使用C18、C19、C20、C21" or not "規則3-3=癌症分期分數或結果為M>=1" or not "規則3-5=用藥線別為第一線")
    then '<主要規定一：初次使用條件>\n' +
         (if not "規則2=K-RAS基因及N-RAS基因沒有突變" 
           then '▲ 規則2：K-RAS基因或N-RAS基因有突變或未提供檢測結果\n' else '') +
         (if not Reusable."主要疾病之ICD-10使用C18、C19、C20、C21" 
           then '▲ 規則3-1：主要疾病之ICD代碼未使用C18、C19、C20、C21\n' else '') +
         (if not "規則3-3=癌症分期分數或結果為M>=1" 
           then '▲ 規則3-3：癌症分期分數或結果不為M≥1\n' else '') +
         (if not "規則3-5=用藥線別為第一線" 
           then '▲ 規則3-5：用藥線別不為第一線\n' else '') +
         '\n'  
    else '') +
  
  // 主要規定三：藥品使用規則 - 代碼條件不符
  (if not "3規則1" or not "規則2"
    then '<主要規定三：藥品使用規則>\n' +
         (if not "3規則1"
           then '▲ 規則3-1：Panitumumab與Cetuximab使用規定不符\n' +
                (if "規則1-2=無法忍受化療(其副作用)時(有註記)" and not "規則1-3=Panitumumab與Cetuximab使用時間不重疊"
                  then '  （有「無法忍受化療副作用」註記，但Panitumumab與Cetuximab使用時間重疊）\n'
                  else if not "規則1-2=無法忍受化療(其副作用)時(有註記)" and not "規則1-1=Panitumumab與Cetuximab二者僅能擇一使用"
                  then '  （無「無法忍受化療副作用」註記，但二者同時使用）\n'
                  else '')
           else '') +
         (if not "規則1-4=每次申請事前審查之療程以18週為限" 
           then '▲ 規則3-1-3：每次申請事前審查之療程超過18週上限\n' else '') +
         (if not ("規則2-1=未使用Bevacizumab藥品" or "規則2-2=本藥品未與Bevacizumab併用")
           then '▲ 規則3-2：因與Bevacizumab併用，故不符合本藥品之使用規則\n' else '')
    else '')

//============================================
// 列出「不符合」項目判斷式 - 必要資料未填寫
//============================================

define function "不符合項目_必要資料未填寫"():
  // 主要規定一：初次使用條件 - 必要資料未填寫
  (if "初次申請" and (not "規則1" or not ("規則3-2=三個月內有影像檢查報告" or "規則3-4=三個月內有檢查報告"))
    then '<主要規定一：初次使用條件>\n' +
         (if not "規則1"
           then '▲ 規則1：未提供化學療法併用資料（需有FOLFOX或FOLFIRI之處方）\n' else '') +
         (if not ("規則3-2=三個月內有影像檢查報告" or "規則3-4=三個月內有檢查報告")
           then '▲ 規則3-2/3-4：未提供三個月內影像檢查報告或檢查報告\n' else '') +
         '\n'  
    else '') +
  
  // 主要規定二：續用條件 - 必要資料未填寫
  (if "續用申請" and not "規則1=再次申請必須提出客觀證據(如：影像學)證實無惡化，才可繼續使用"
    then '<主要規定二：續用條件－治療持續給付>\n' +
         '▲ 續用規則1：未提供客觀證據（如：影像學）\n' +
         '\n'  
    else '')

//============================================
// 審核結果
//============================================

define "大腸直腸癌Panitumumab申請結果_布林":
  case
    when "初次申請" then (
      "規則1" and
      "規則2=K-RAS基因及N-RAS基因沒有突變" and
      "規則3" and
      "3規則1" and  
      "規則2"
    )
    when "續用申請" then (
      "規則1=再次申請必須提出客觀證據(如：影像學)證實無惡化，才可繼續使用" and
      "3規則1" and  
      "規則2"
    )
    else false
  end

define "大腸直腸癌Panitumumab申請結果":
  if (
    "初次申請" and 
    "規則1" and
    "規則2=K-RAS基因及N-RAS基因沒有突變" and
    "規則3" and
    "3規則1" and  
    "規則2"
  )
  then '✓通過：初次使用－大腸直腸癌 Panitumumab 用藥申請'
  else if (
    "續用申請" and
    "規則1=再次申請必須提出客觀證據(如：影像學)證實無惡化，才可繼續使用" and
    "3規則1" and  
    "規則2"
  )
  then '✓通過：續用－大腸直腸癌 Panitumumab 用藥申請'
  else if "初次申請"
  then '✖不通過：初次使用－大腸直腸癌 Panitumumab 用藥申請'
  else if "續用申請"
  then '✖不通過：續用－大腸直腸癌 Panitumumab 用藥申請'
  else '✖不通過：無法判定申請類型－大腸直腸癌 Panitumumab 用藥申請'

//============================================
// 審核報告總結
//============================================

define "報告總結":
  '\n=== 大腸直腸癌之Panitumumab 申請審核報告 ===\n' +
  '\n【申請類型】' + "申請類型" + '\n' +
  '\n【●符合項目】\n' +
  (if "符合項目"() = '' then '無\n' else "符合項目"()) +
  '\n【▲不符合項目 - 代碼或條件不符】\n' +
  (if "不符合項目_代碼或條件不符"() = '' then '無\n' else "不符合項目_代碼或條件不符"()) +
  '\n【▲不符合項目 - 必要資料未填寫】\n' +
  (if "不符合項目_必要資料未填寫"() = '' then '無\n' else "不符合項目_必要資料未填寫"()) +
  '\n【申請結果】\n' +
  "大腸直腸癌Panitumumab申請結果" +
  '\n===============================================\n'