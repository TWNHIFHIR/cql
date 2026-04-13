//乳癌_CDK46給付規定
library BCCDK46Rule1 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

include BCCodeConcept version '1.0.0' called CodeConcept

include BCReusable version '1.0.0' called Reusable

context Patient



//============================================
// 主要規定一：初次使用條件
//============================================

/*規則1*/

define "ICD代碼檢核_布林值": Reusable."ICD-10使用C50"

define "醫令類別為1_布林值":Reusable."醫令類別為1"

//條件1:停經後乳癌婦女

//條件1-1
define "條件1-1=簡要病摘含有停經字樣":
    exists (
        [Claim] C
        where exists (
            C.diagnosis D
            where exists (
                D.type.text T
                where Matches(T.value, '(?i).*(停經|停經前|正在停經\\+).*')
            )
        )
    )

//條件1-2
define "條件1-2=女性":
Patient.gender = 'female'

//條件1-3
define "條件1-3=CDK46抑制劑申請":
  exists (        
    [MedicationRequest] MRPlan
    where MRPlan.intent = 'plan'
      and exists (
        MRPlan.medication.coding Cdg
        where Cdg in CodeConcept.NHIMedication
          and Cdg.code in CodeConcept."CDK46抑制劑"
      )
  )


define "條件1-1=停經後乳癌婦女":
"ICD代碼檢核_布林值" and "醫令類別為1_布林值"
and "條件1-1=簡要病摘含有停經字樣" 
and "條件1-2=女性"
and "條件1-3=CDK46抑制劑申請"

//條件2:遠端轉移

//條件2-1
define "ICD腫瘤代碼檢核_布林值": Reusable."ICD-10使用C77、C78、C79"

//條件2-2
define "條件2-2=6個月內影像報告":
Reusable."HasRecentImageReport"("本次申請起始日期", 180)


//條件2-3
define "條件2-3=癌症分期分數或結果為M≠0":
  Reusable."癌症分期分數或結果為M≠0"

define "條件1-2=遠端轉移":
"ICD腫瘤代碼檢核_布林值"
or ("條件2-2=6個月內影像報告"    
and "條件2-3=癌症分期分數或結果為M≠0") 


//條件3:(1)荷爾蒙接受體為：ER或PR >30%。
//條件3-1 ER
define "條件3-1=檢驗檢查-荷爾蒙受體陽性(ER>30%)":
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
      and Cdg.code in CodeConcept.ER
    )
    and (
      (OBs.value is Quantity
        and (OBs.value as Quantity).value > 30
        and (OBs.value as Quantity).comparator = '>'
        and (OBs.value as Quantity).unit = '%')
      or (OBs.value is FHIR.string
        and Matches((OBs.value as FHIR.string).value, '.*ER>30%.*'))
    )
  )

define "條件3-1=基因檢測-荷爾蒙受體陽性(ER>30%)":
  exists (
    [Observation] OBs
      where exists (
        OBs.category C
          where exists (
            C.coding Cdg
              where Cdg in CodeConcept.NHIPASSupportingInfoType
                and Cdg.code = 'geneInfo'
          )
      )
    and exists (
      OBs.code.coding Cdg
      where Cdg in CodeConcept.LOINC
      and Cdg.code = '69548-6'
    )
    and exists (
      OBs.component Comp
        where exists (
          Comp.code.coding Cdg
            where Cdg in CodeConcept.LOINC
              and Cdg.code in CodeConcept.ER
        )
        and (
          (Comp.value is Quantity
            and (Comp.value as Quantity).value > 30
            and (Comp.value as Quantity).comparator = '>'
            and (Comp.value as Quantity).unit = '%')
          or (Comp.value is FHIR.string
            and Matches((Comp.value as FHIR.string).value, '.*ER>30%.*'))
        )
    )
  )

define "條件3-1=荷爾蒙受體陽性(ER>30%)":
  "條件3-1=檢驗檢查-荷爾蒙受體陽性(ER>30%)"
  or "條件3-1=基因檢測-荷爾蒙受體陽性(ER>30%)"

//條件3-2 PR
define "條件3-2=檢驗檢查-荷爾蒙受體陽性(PR>30%)":
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
      and Cdg.code in CodeConcept.PR
    )
    and (
      (OBs.value is Quantity
        and (OBs.value as Quantity).value > 30
        and (OBs.value as Quantity).comparator = '>'
        and (OBs.value as Quantity).unit = '%')
      or (OBs.value is FHIR.string
        and Matches((OBs.value as FHIR.string).value, '.*PR>30%.*'))
    )
  )

define "條件3-2=基因檢測-荷爾蒙受體陽性(PR>30%)":
  exists (
    [Observation] OBs
      where exists (
        OBs.category C
          where exists (
            C.coding Cdg
              where Cdg in CodeConcept.NHIPASSupportingInfoType
                and Cdg.code = 'geneInfo'
          )
      )
    and exists (
      OBs.code.coding Cdg
      where Cdg in CodeConcept.LOINC
      and Cdg.code = '69548-6'
    )
    and exists (
      OBs.component Comp
        where exists (
          Comp.code.coding Cdg
            where Cdg in CodeConcept.LOINC
              and Cdg.code in CodeConcept.PR
        )
        and (
          (Comp.value is Quantity
            and (Comp.value as Quantity).value > 30
            and (Comp.value as Quantity).comparator = '>'
            and (Comp.value as Quantity).unit = '%')
          or (Comp.value is FHIR.string
            and Matches((Comp.value as FHIR.string).value, '.*PR>30%.*'))
        )
    )
  )

define "條件3-2=荷爾蒙受體陽性(PR>30%)":
  "條件3-2=檢驗檢查-荷爾蒙受體陽性(PR>30%)"
  or "條件3-2=基因檢測-荷爾蒙受體陽性(PR>30%)"


define "條件3=荷爾蒙接受體為：ER或PR >30%":
"條件3-1=荷爾蒙受體陽性(ER>30%)" or "條件3-2=荷爾蒙受體陽性(PR>30%)"


//條件4:(2)HER-2 檢測為陰性
define "條件4=HER-2 檢測為陰性":
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
      and Cdg.code in CodeConcept.HER2
    )
    and exists (
      OBs.interpretation.coding INT
      where INT in CodeConcept.InterpretationCodes
        and INT.code in {'NEG', 'ND'}
    )
  )
  or exists (
    [Observation] OBs
      where exists (
        OBs.category C
          where exists (
            C.coding Cdg
              where Cdg in CodeConcept.NHIPASSupportingInfoType
                and Cdg.code = 'geneInfo'
          )
      )
    and exists (
      OBs.code.coding Cdg
      where Cdg in CodeConcept.LOINC
      and Cdg.code = '69548-6'
    )
    and exists (
      OBs.component Comp
        where exists (
          Comp.code.coding Cdg
            where Cdg in CodeConcept.LOINC
              and Cdg.code in CodeConcept.HER2
        )
        and exists (
          Comp.interpretation.coding INT
            where INT in CodeConcept.InterpretationCodes
              and INT.code in {'NEG'}
        )
    )
  )
//條件5:經完整疾病評估後未出現器官轉移危急症狀 (visceral crisis)且無中樞神經系統(CNS)轉移
//條件5-1
define "條件5-1=未出現器官轉移危急症狀 (visceral crisis)":
  exists (
    [DiagnosticReport] O
    where exists (
      O.code.coding Cdg
      where (
        Cdg in CodeConcept.ICD10PCS2023Image
        or Cdg in CodeConcept.ICD10PCS2014Image
      )
      and Cdg.code in CodeConcept.ImageCodes
    )
    and O.effective is not null
    and FHIRHelpers.ToDateTime(O.effective) >= "本次申請起始日期" - 180 days
    and FHIRHelpers.ToDateTime(O.effective) <= "本次申請起始日期"
    and O.conclusion is not null
    and Matches(O.conclusion, '(?i).*(no visceral crisis|\\+).*')
  ) 

//條件5-2
define "條件5-2=無中樞神經系統(CNS)轉移":
  exists (
    [DiagnosticReport] O
    where exists (
      O.code.coding Cdg
      where (
        Cdg in CodeConcept.ICD10PCS2023Image
        or Cdg in CodeConcept.ICD10PCS2014Image
      )
      and Cdg.code in CodeConcept.ImageCodes
    )
    and O.effective is not null
    and FHIRHelpers.ToDateTime(O.effective) >= "本次申請起始日期" - 180 days
    and FHIRHelpers.ToDateTime(O.effective) <= "本次申請起始日期"
    or Reusable."ICD-10使用C77、C78、C79但排除C79.3"
  )

define "條件5=經完整疾病評估後未出現器官轉移危急症狀 (visceral crisis)且無中樞神經系統(CNS)轉移":
"條件5-1=未出現器官轉移危急症狀 (visceral crisis)"
and "條件5-2=無中樞神經系統(CNS)轉移"

//條件6:骨轉移不可為唯一轉移部位
define "條件6=骨轉移不可為唯一轉移部位":
  exists (
    [DiagnosticReport] O
    where exists (
      O.code.coding Cdg
      where (
        Cdg in CodeConcept.ICD10PCS2023Image
        or Cdg in CodeConcept.ICD10PCS2014Image
      )
      and Cdg.code in CodeConcept.ImageCodes
    )
    and O.effective is not null
    and FHIRHelpers.ToDateTime(O.effective) >= "本次申請起始日期" - 180 days
    and FHIRHelpers.ToDateTime(O.effective) <= "本次申請起始日期"
  )

//條件7:且滿足下列條件之一：
//Ⅰ.年齡滿55歲。
//II.曾接受雙側卵巢切除術。
//III.FSH及estradiol血液檢測值在停經後數值範圍內。


//條件7-1
define "病患目前未接受卵巢功能抑制治療 (包含GnRH analogue等)":
  not exists (
    [MedicationRequest] MROrder1
    where (MROrder1.intent = 'plan' or MROrder1.intent = 'order')
      and (MROrder1.status is null or MROrder1.status in { 'active', 'completed' })
      and exists (
        MROrder1.medication.coding Cdg
        where Cdg in CodeConcept.NHIMedication
          and Cdg.code in CodeConcept."卵巢功能抑制治療"
      )
      and exists MROrder1.dosageInstruction
      and MROrder1.dosageInstruction[0].timing.repeat.bounds is Period
      // 用藥期間與過去180天有重疊
      and (MROrder1.dosageInstruction[0].timing.repeat.bounds as Period) 
          overlaps Interval["本次申請起始日期" - 180 days, "本次申請起始日期"]
  )

//條件7-2
define "條件7-2=年齡滿55歲":
 AgeInYears() >= 55

//條件7-3
define "條件7-3=曾接受雙側卵巢切除術":
  exists (
    [Claim] C
    where exists (
      C.procedure CP
      where exists (
        CP.procedure.coding Pcoding
        where Pcoding.code.value in CodeConcept.BilateralOvaries
      )
    )
  )
  or (
    exists (
      [Claim] C
      where exists (
        C.procedure CP
        where exists (
          CP.procedure.coding Pcoding
          where Pcoding.code.value in CodeConcept.RightOvary
        )
      )
    )
    and exists (
      [Claim] C
      where exists (
        C.procedure CP
        where exists (
          CP.procedure.coding Pcoding
          where Pcoding.code.value in CodeConcept.LeftOvary
        )
      )
    )
  )


//條件7-4:FSH及estradiol血液檢測值在停經後數值範圍內
//條件7-4-1
define "條件7-4-1=FSH血液檢測值在停經後數值範圍內":
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
      and Cdg.code in CodeConcept.FSH
    )
      and OBs.value is Quantity
      and (OBs.value as Quantity).value > 30
      and (OBs.value as Quantity).comparator = '>'
      and (OBs.value as Quantity).unit = 'IU/L'
  )

//條件7-4-2
define "條件7-4-2=Estradiol血液檢測值在停經後數值範圍內":
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
      and Cdg.code in CodeConcept.Estradiol
    )
      and OBs.value is Quantity
      and (OBs.value as Quantity).value < 35
      and (OBs.value as Quantity).comparator = '<'
      and (OBs.value as Quantity).unit = 'pg/ml'
  )

define "條件7-4=FSH及estradiol血液檢測值在停經後數值範圍內":
"條件7-4-1=FSH血液檢測值在停經後數值範圍內"
and "條件7-4-2=Estradiol血液檢測值在停經後數值範圍內"

define "條件7":
"病患目前未接受卵巢功能抑制治療 (包含GnRH analogue等)"
and ("條件7-2=年齡滿55歲"
or "條件7-3=曾接受雙側卵巢切除術"
or "條件7-4=FSH及estradiol血液檢測值在停經後數值範圍內")

//主要規定一之規則1
define "主要規定一之規則1":
"條件1-1=停經後乳癌婦女"
and "條件1-2=遠端轉移"
and "條件3=荷爾蒙接受體為：ER或PR >30%"
and "條件4=HER-2 檢測為陰性"
and "條件5=經完整疾病評估後未出現器官轉移危急症狀 (visceral crisis)且無中樞神經系統(CNS)轉移"
and "條件6=骨轉移不可為唯一轉移部位"
and "條件7"



/*規則2*/

//條件1:同規則1的條件1

//條件2:同規則1的條件2

//條件3:與芳香環轉化酶抑制劑及GnRH analogue併用
define "條件3=與芳香環轉化酶抑制劑及GnRH analogue併用":
  Reusable."HasConcurrentMedicationOrders2"(
    CodeConcept."CDK46抑制劑",
    CodeConcept."芳香環轉化酶抑制劑",
    CodeConcept."GnRH analogue"
  )
  and Reusable."醫令類別為1"


//條件4:同規則1的條件3

//條件5:同規則1的條件4

//條件6:同規則1的條件5

//主要規定一之規則2
define "主要規定一之規則2":
"條件1-1=停經後乳癌婦女"
and "條件1-2=遠端轉移"
and "條件3=與芳香環轉化酶抑制劑及GnRH analogue併用"
and "條件3=荷爾蒙接受體為：ER或PR >30%"
and "條件4=HER-2 檢測為陰性"
and "條件5=經完整疾病評估後未出現器官轉移危急症狀 (visceral crisis)且無中樞神經系統(CNS)轉移"
and "條件6=骨轉移不可為唯一轉移部位"


// 主要規定一
define "主要規定一":
"主要規定一之規則1" or "主要規定一之規則2"



//============================================
// 主要規定二：續用條件－治療持續給付
//============================================

//條件1:每24週須再次申請並檢附療效評估資料

// 本次申請紀錄（以最新一筆申請作為本次申請）
define "本次申請紀錄":
  Reusable."LatestMedicationPlan"(CodeConcept."CDK46抑制劑")

define "本次申請起始日期":
  Reusable."GetStartTime"("本次申請紀錄")

// 前次申請紀錄（本次申請之前最近一次的申請）
define "前次申請紀錄":
  Reusable."LatestMedicationPlanBefore"(CodeConcept."CDK46抑制劑", "本次申請起始日期")

// 檢查本次申請療程長度是否在24週內
define "條件1=每24週須再次申請並檢附療效評估資料":
  Reusable."醫令類別為1" 
  and Reusable."續用註記為2"
  and "本次申請紀錄" is not null
  and (
    // 計算本次申請起始日期到終止日期的天數差異
    difference in days between
      FHIRHelpers.ToDateTime(("本次申請紀錄".dosageInstruction[0].timing.repeat.bounds as Period).start)
      and FHIRHelpers.ToDateTime(("本次申請紀錄".dosageInstruction[0].timing.repeat.bounds as Period).end)
  ) <= 168  // 24週 = 168天


//條件2:疾病有惡化情形須停止使用

// 取得前次治療紀錄（最近一次已完成的治療）
define "前次治療紀錄":
  Reusable."LatestCompletedMedicationOrderBefore"(CodeConcept."CDK46抑制劑", "本次申請起始日期")

// 前次用藥開始日期
define "前次用藥開始日期":
  Reusable."GetStartTime"("前次治療紀錄")

// 規則1-2: 疾病有惡化情形須停止使用(續用須檢附前次治療後影像學報告)
define "條件2=疾病有惡化情形須停止使用":
  exists (
    [DiagnosticReport] O
    where exists (
      O.code.coding Cdg
      where (
        Cdg in CodeConcept.ICD10PCS2023Image
        or Cdg in CodeConcept.ICD10PCS2014Image
      )
      and Cdg.code in CodeConcept.ImageCodes
    )
    and O.effective is not null
    and FHIRHelpers.ToDateTime(O.effective) >= "前次用藥開始日期"
    and FHIRHelpers.ToDateTime(O.effective) < "本次申請起始日期"
  )

// 主要規定二
define "主要規定二：續用條件":
Reusable."續用註記為2"
and Reusable."醫令類別為1"
and "本次申請紀錄" is not null
and "條件1=每24週須再次申請並檢附療效評估資料"
and "條件2=疾病有惡化情形須停止使用"



//============================================
// 主要規定三：藥品使用規則
//============================================


//條件1:(1)ribociclib每日最多處方3粒
define "條件1=ribociclib每日最多處方3粒":
  exists (
    [MedicationRequest] MR
    where MR.intent = 'plan'
    and exists (
      MR.medication.coding Cdg
      where Cdg in CodeConcept.NHIMedication
      and Cdg.code in CodeConcept.L01EF02
        )
    and exists (
      MR.dosageInstruction DI
      where exists (
        DI.timing.code.coding C
        where C.code = 'QD'
      )
      and exists (
        DI.doseAndRate DR
        where (DR.dose as FHIR.SimpleQuantity) is not null
        and (DR.dose as FHIR.SimpleQuantity).value <= 3
        and (DR.dose as FHIR.SimpleQuantity).code = '{tbl}'
      )
    )
  )

//條件2:(2)palbociclib每日最多處方1粒
define "條件2=palbociclib每日最多處方1粒":
  exists (
    [MedicationRequest] MR
    where MR.intent = 'plan'
    and exists (
      MR.medication.coding Cdg
      where Cdg in CodeConcept.NHIMedication
      and Cdg.code in CodeConcept.L01EF01
        )
    and exists (
      MR.dosageInstruction DI
      where exists (
        DI.timing.code.coding C
        where C.code = 'QD'
      )
      and exists (
        DI.doseAndRate DR
        where (DR.dose as FHIR.SimpleQuantity) is not null
        and (DR.dose as FHIR.SimpleQuantity).value <= 1
        and (DR.dose as FHIR.SimpleQuantity).code = '{tbl}'
      )
    )
  )
//條件3:(3)本類藥品僅得擇一使用，唯有在耐受不良時方可轉換使用
//條件3-1:可忍受化療(其副作用)時（一般情況，不另外註記）

//條件3-2
define "條件3-2=Ribociclib、Palbociclib二者僅能擇一使用":
  not (
    Reusable."HasMedicationUse"(CodeConcept.L01EF01)
    and Reusable."HasMedicationUse"(CodeConcept.L01EF02)
  )

//條件3-3:無法忍受化療(其副作用)時（有註記）
define "條件3-3=無法忍受化療(其副作用)時(有註記)":
  exists (
    [Claim] C
      where exists (
        C.diagnosis D
          where exists (
            D.type.text T
              where Matches(T.value, '(?i).*無法忍受副作用.*')
            )
        )
    )

//條件3-4
define "條件3-4=ribociclib、palbociclib二者可轉換":
  Reusable."HasMedicationUse"(CodeConcept.L01EF01)
  or Reusable."HasMedicationUse"(CodeConcept.L01EF02)

define "條件3=本類藥品僅得擇一使用，唯有在耐受不良時方可轉換使用":
  if "條件3-3=無法忍受化療(其副作用)時(有註記)"
    then "條件3-4=ribociclib、palbociclib二者可轉換"
  else
    "條件3-2=Ribociclib、Palbociclib二者僅能擇一使用"

//條件4
define "條件4=使用總療程合併計算，以每人終生給付24個月為上限":
  Reusable."HasMedicationTotalDurationWithin"(CodeConcept."CDK46抑制劑", 720)

//條件5:everolimus無效，不得再申請CDK4/6抑制劑
define "條件5=未註記everolimus無效":
  not exists (
    [Claim] C
      where exists (
        C.diagnosis D
          where exists (
            D.type.text T
              where Matches(T.value, '(?i).*everolimus無效.*')
            )
        )
    )

//條件6:abemaciclib無效，不得再申請CDK4/6抑制劑
define "條件6=未註記abemaciclib無效":
  not exists (
    [Claim] C
      where exists (
        C.diagnosis D
          where exists (
            D.type.text T
              where Matches(T.value, '(?i).*abemaciclib無效.*')
            )
        )
    )

// 主要規定三
define "主要規定三：藥品使用規則":
("條件1=ribociclib每日最多處方3粒"
or "條件2=palbociclib每日最多處方1粒")
and "條件3=本類藥品僅得擇一使用，唯有在耐受不良時方可轉換使用"
and "條件4=使用總療程合併計算，以每人終生給付24個月為上限"
and "條件5=未註記everolimus無效"
and "條件6=未註記abemaciclib無效"


//============================================
// 列出「符合」項目判斷式
//============================================

define function "符合項目"():
  // 主要規定一：初次使用條件
  (if Reusable."初次申請" and (
    "條件1-1=停經後乳癌婦女" or 
    "條件1-2=遠端轉移" or 
    "條件3=荷爾蒙接受體為：ER或PR >30%" or 
    "條件4=HER-2 檢測為陰性" or 
    "條件5=經完整疾病評估後未出現器官轉移危急症狀 (visceral crisis)且無中樞神經系統(CNS)轉移" or 
    "條件6=骨轉移不可為唯一轉移部位" or 
    "條件7" or 
    "主要規定一之規則2"
  )
    then '<主要規定一：初次使用條件>\n' +
         (if "條件1-1=簡要病摘含有停經字樣" 
           then '● 條件1-1：簡要病摘含有停經字樣\n' else '') +
         (if "條件1-2=女性" 
           then '● 條件1-2：女性\n' else '') +
         (if "條件1-3=CDK46抑制劑申請" 
           then '● 條件1-3：CDK46抑制劑申請\n' else '') +
         (if "ICD腫瘤代碼檢核_布林值" 
           then '● ICD腫瘤代碼檢核：ICD-10使用C77、C78、C79\n' else '') +
         (if "條件2-2=6個月內影像報告" 
           then '● 條件2-2：6個月內影像報告\n' else '') +
         (if "條件2-3=癌症分期分數或結果為M≠0" 
           then '● 條件2-3：癌症分期分數或結果為M≠0\n' else '') +
         (if "條件3-1=荷爾蒙受體陽性(ER>30%)" 
           then '● 條件3-1：荷爾蒙受體陽性(ER>30%)\n' else '') +
         (if "條件3-2=荷爾蒙受體陽性(PR>30%)" 
           then '● 條件3-2：荷爾蒙受體陽性(PR>30%)\n' else '') +
         (if "條件4=HER-2 檢測為陰性" 
           then '● 條件4：HER-2檢測為陰性\n' else '') +
         (if "條件5-1=未出現器官轉移危急症狀 (visceral crisis)" 
           then '● 條件5-1：未出現器官轉移危急症狀(visceral crisis)\n' else '') +
         (if "條件5-2=無中樞神經系統(CNS)轉移" 
           then '● 條件5-2：無中樞神經系統(CNS)轉移\n' else '') +
         (if "條件6=骨轉移不可為唯一轉移部位" 
           then '● 條件6：骨轉移不為唯一轉移部位(已檢附影像報告)\n' else '') +
         (if "條件7-2=年齡滿55歲" 
           then '● 條件7-2：年齡滿55歲\n' else '') +
         (if "條件7-3=曾接受雙側卵巢切除術" 
           then '● 條件7-3：曾接受雙側卵巢切除術\n' else '') +
         (if "條件7-4-1=FSH血液檢測值在停經後數值範圍內"
           then '● 條件7-4-1：FSH檢測值符合停經後標準\n' else '') +
         (if "條件7-4-2=Estradiol血液檢測值在停經後數值範圍內"
           then '● 條件7-4-2：Estradiol檢測值符合停經後標準\n' else '') +
         (if "條件3=與芳香環轉化酶抑制劑及GnRH analogue併用" 
           then '● 條件3：與芳香環轉化酶抑制劑及GnRH analogue併用\n' else '') +
         '\n'
    else '') +
  
  // 主要規定二：續用條件
  (if Reusable."續用申請" and (
    "條件1=每24週須再次申請並檢附療效評估資料" or 
    "條件2=疾病有惡化情形須停止使用"
  )
    then '<主要規定二：續用條件－治療持續給付>\n' +
         (if "條件1=每24週須再次申請並檢附療效評估資料" 
           then '● 續用條件1：於24週內再次申請並檢附療效評估資料\n' else '') +
         (if "條件2=疾病有惡化情形須停止使用" 
           then '● 續用條件2：已檢附前次治療後影像學報告，確認無惡化\n' else '') +
         '\n'
    else '') +
  
  // 主要規定三：藥品使用規則
  (if "條件1=ribociclib每日最多處方3粒" or 
      "條件2=palbociclib每日最多處方1粒" or
      "條件3=本類藥品僅得擇一使用，唯有在耐受不良時方可轉換使用" or
      "條件4=使用總療程合併計算，以每人終生給付24個月為上限" or
      "條件5=未註記everolimus無效" or
      "條件6=未註記abemaciclib無效"
    then '<主要規定三：藥品使用規則>\n' +
         // 只顯示實際申請的藥品劑量規定
         (if "條件1=ribociclib每日最多處方3粒" 
           then '● 條件1：ribociclib每日劑量≤3粒\n' 
           else if "條件2=palbociclib每日最多處方1粒" 
           then '● 條件2：palbociclib每日劑量≤1粒\n' 
           else '') +
         (if "條件3=本類藥品僅得擇一使用，唯有在耐受不良時方可轉換使用" 
           then '● 條件3：藥品擇一使用或符合轉換條件\n' else '') +
         (if "條件4=使用總療程合併計算，以每人終生給付24個月為上限" 
           then '● 條件4：使用總療程≤24個月(720天)\n' else '') +
         (if "條件5=未註記everolimus無效" 
           then '● 條件5：未註記everolimus無效\n' else '') +
         (if "條件6=未註記abemaciclib無效" 
           then '● 條件6：未註記abemaciclib無效\n' else '')
    else '')

//============================================
// 列出「不符合」項目判斷式 - 代碼或條件不符
//============================================

define function "不符合項目_代碼或條件不符"():
  // 主要規定一：初次使用條件 - 代碼條件不符
  (if Reusable."初次申請" and (
    not Reusable."ICD-10使用C50" or 
    not "條件1-2=女性"
  )
    then '<主要規定一：初次使用條件>\n' +
         (if not Reusable."ICD-10使用C50" 
           then '▲ ICD代碼檢核：主要疾病之ICD代碼未使用C50\n' else '') +
         (if not "條件1-2=女性" 
           then '▲ 條件1-2：非女性\n' else '') +
         '\n'
    else '') +
  
  // 主要規定三：藥品使用規則 - 代碼條件不符
  (if (not "條件1=ribociclib每日最多處方3粒" and not "條件2=palbociclib每日最多處方1粒") or
      not "條件3=本類藥品僅得擇一使用，唯有在耐受不良時方可轉換使用" or
      not "條件4=使用總療程合併計算，以每人終生給付24個月為上限" or
      not "條件5=未註記everolimus無效" or
      not "條件6=未註記abemaciclib無效"
    then '<主要規定三：藥品使用規則>\n' +
         // 只有當兩個劑量規定都不符合時才顯示錯誤（表示沒有申請或劑量都超標）
         (if not "條件1=ribociclib每日最多處方3粒" and not "條件2=palbociclib每日最多處方1粒"
           then '▲ 條件1/2：未申請CDK46抑制劑或劑量超標\n' else '') +
         (if not "條件3=本類藥品僅得擇一使用，唯有在耐受不良時方可轉換使用" 
           then '▲ 條件：藥品使用不符規定(本類藥品僅得擇一使用，唯有在耐受不良時方可轉換使用)\n' else '') +
         (if not "條件4=使用總療程合併計算，以每人終生給付24個月為上限" 
           then '▲ 條件4：使用總療程超過24個月(720天)\n' else '') +
         (if not "條件5=未註記everolimus無效" 
           then '▲ 條件5：病歷註記everolimus無效\n' else '') +
         (if not "條件6=未註記abemaciclib無效" 
           then '▲ 條件6：病歷註記abemaciclib無效\n' else '')
    else '')

//============================================
// 列出「不符合」項目判斷式 - 必要資料未填寫
//============================================

define function "不符合項目_必要資料未填寫"():
  // 主要規定一：初次使用條件 - 必要資料未填寫
  (if Reusable."初次申請" and (
    not "條件1-1=簡要病摘含有停經字樣" or 
    not "條件1-3=CDK46抑制劑申請" or 
    not "條件1-2=遠端轉移" or 
    not "條件3=荷爾蒙接受體為：ER或PR >30%" or 
    not "條件4=HER-2 檢測為陰性" or 
    not "條件5=經完整疾病評估後未出現器官轉移危急症狀 (visceral crisis)且無中樞神經系統(CNS)轉移" or 
    not "條件6=骨轉移不可為唯一轉移部位" or 
    not "條件7"
  )
    then '<主要規定一：初次使用條件>\n' +
         (if not "條件1-1=簡要病摘含有停經字樣" 
           then '▲ 條件1-1：簡要病摘未含有停經字樣\n' else '') +
         (if not "條件1-3=CDK46抑制劑申請" 
           then '▲ 條件1-3：未提供CDK46抑制劑申請資料\n' else '') +
         (if not "條件1-2=遠端轉移" 
           then '▲ 條件1-2：未提供遠端轉移證據(缺少ICD腫瘤代碼或影像報告、分期資料)\n' else '') +
         (if not "條件3=荷爾蒙接受體為：ER或PR >30%" 
           then '▲ 條件3：未提供荷爾蒙受體檢測資料或未達陽性標準(ER或PR>30%)\n' else '') +
         (if not "條件4=HER-2 檢測為陰性" 
           then '▲ 條件4：未提供HER-2檢測資料或HER-2非陰性\n' else '') +
         (if not "條件5-1=未出現器官轉移危急症狀 (visceral crisis)"
           then '▲ 條件5-1：有visceral crisis或未提供評估資料\n' else '') +
         (if not "條件5-2=無中樞神經系統(CNS)轉移"
           then '▲ 條件5-2：有CNS轉移或未提供評估資料\n' else '') +
         (if not "條件6=骨轉移不可為唯一轉移部位" 
           then '▲ 條件6：未提供影像報告證明骨轉移非唯一轉移部位\n' else '') +
         (if not "條件7"
           then (if not "條件7-2=年齡滿55歲" then '▲ 條件7-2：年齡未滿55歲\n' else '') +
                (if not "條件7-3=曾接受雙側卵巢切除術" then '▲ 條件7-3：未提供雙側卵巢切除術紀錄\n' else '') +
                (if not "條件7-4-1=FSH血液檢測值在停經後數值範圍內" then '▲ 條件7-4-1：FSH檢測值未達停經後標準\n' else '') +
                (if not "條件7-4-2=Estradiol血液檢測值在停經後數值範圍內" then '▲ 條件7-4-2：Estradiol檢測值未達停經後標準\n' else '')
           else '') +
         '\n'
    else '') +
  
  // 主要規定二：續用條件 - 必要資料未填寫
  (if Reusable."續用申請" and (
    not "條件1=每24週須再次申請並檢附療效評估資料" or 
    not "條件2=疾病有惡化情形須停止使用"
  )
    then '<主要規定二：續用條件－治療持續給付>\n' +
         (if not "條件1=每24週須再次申請並檢附療效評估資料" 
           then '▲ 續用條件1：未於24週內再次申請或未檢附療效評估資料\n' else '') +
         (if not "條件2=疾病有惡化情形須停止使用" 
           then '▲ 續用條件2：未提供前次治療後影像學報告或顯示疾病惡化\n' else '') +
         '\n'
    else '')

//============================================
// 審核結果
//============================================

define "乳癌CDK46抑制劑申請結果_布林":
  case
    when Reusable."初次申請" then (
      "主要規定一" and
      "主要規定三：藥品使用規則"
    )
    when Reusable."續用申請" then (
      "主要規定二：續用條件" and
      "主要規定三：藥品使用規則"
    )
    else false
  end

define "乳癌CDK46抑制劑申請之CQL檢核結果":
  if (
    Reusable."初次申請" and 
    "主要規定一" and
    "主要規定三：藥品使用規則"
  )
  then '✓通過：初次使用－乳癌CDK46抑制劑用藥申請'

  else if (
    Reusable."續用申請" and
    "主要規定二：續用條件" and
    "主要規定三：藥品使用規則"
  )
  then '✓通過：續用－乳癌 CDK46抑制劑 用藥申請'
  else if Reusable."初次申請"
  then '✖不通過：初次使用－乳癌 CDK46抑制劑 用藥申請'
  else if Reusable."續用申請"
  then '✖不通過：續用－乳癌 CDK46抑制劑 用藥申請'
  else '✖不通過：無法判定申請類型－乳癌 CDK46抑制劑 用藥申請'

//============================================
// 報告總結
//============================================

define "報告總結":
  '\n=== 乳癌之CDK46抑制劑申請審核報告 ===\n' +
  '\n【申請類型】' + Reusable."申請類型" + '\n' +
  '\n【●符合項目】\n' +
  (if "符合項目"() = '' then '無\n' else "符合項目"()) +
  '\n【▲不符合項目 - 代碼或條件不符】\n' +
  (if "不符合項目_代碼或條件不符"() = '' then '無\n' else "不符合項目_代碼或條件不符"()) +
  '\n【▲不符合項目 - 必要資料未填寫】\n' +
  (if "不符合項目_必要資料未填寫"() = '' then '無\n' else "不符合項目_必要資料未填寫"()) +
  '\n【申請結果】\n' +
  "乳癌CDK46抑制劑申請之CQL檢核結果" +
  '\n===============================================\n'
