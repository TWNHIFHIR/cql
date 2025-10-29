### 專案介紹

<div  style="padding-left: 10px;"> 

<p>臺灣健保預檢規則實作指引（Taiwan NHI Clinical Quality Language Implementation Guide，TW NHIA CQL IG）係採用 HL7® FHIR® （Fast Healthcare Interoperability Resources）與 HL7® CQL （Clinical Quality Language）之標準建置方法，並以「臺灣健保癌症用藥事前審查實作指引」（Taiwan NHI Cancer Prior Authorization Support Implementation Guide，TWPAS IG）為基礎，進一步定義符合「癌藥預檢規則」邏輯需求之 CQL Library （邏輯模組）。</br></br>
其中，Library（邏輯模組） 為 CQL 中封裝並可重複使用之規則邏輯基本單位，可供其他規則、量測（Measure）或臨床決策支援模組（Clinical Decision Support, CDS）引用，以促進邏輯之模組化、標準化與重用性。</br></br>
本實作指引內容涵蓋預檢規則條件、資料檢核邏輯、共用函式及代碼定義等多個 Library （邏輯模組），以確保邏輯規則於不同應用情境中具備一致性與可維護性。</p>

</div>

### 專案背景

<div  style="padding-left: 10px;"> 

<p>衛生福利部中央健康保險署規劃建立癌症用藥預檢規則，推動癌症用藥事前審查之數位化與智慧化。為扣合「國家癌症防治計畫」建立智慧醫療的基石政策，本署刻正規劃以結構化、模組化及可重用的方式，建置健保用藥預檢規則邏輯，促進預檢規則於不同系統間的標準化與互通性，提升審查流程之效率與一致性，達成自動化審查與決策支援之目標。</p>

</div>

### 如何閱讀這個實作指引(IG)
<div  style="padding-left: 10px;"> 
<p>本IG之網站架構圖如下圖所示。各功能說明如下：</p>

<ul>
    <li><strong><a href="index.html">應用說明</a></strong>：本IG介紹及背景說明。</li>
    <li><strong><a href="libraries.html">預檢規則(CQL)</a></strong>：本IG所定義之預檢規則，即CQL規則。</li>
    <li><strong><a href="https://nhicore.nhi.gov.tw/cql/history.html">版本異動</a></strong>：若本IG網站的版本有所異動。</li>
</ul>
</div>


### 作者與貢獻者
<table class="grid" style="width:100%">
<thead>
<tr class="header">
<th style="width:10%">角色</th>
<th style="width:10%">姓名</th>
<th style="width:40%">機構</th>
</tr>
</thead>
<tbody>
<tr>
<td>作者-IG</td>
    <td>李麗惠</td>
    <td rowspan="2" style="vertical-align: middle;">國立臺北護理健康大學-健康事業管理系
</td>
</tr>
<tr>
    <td>作者-IG</td>
    <td>李奇安</td>
</tr>
<tr>
    <td>貢獻者-IG</td>
    <td>張如薰</td>
    <td rowspan="3" style="vertical-align: middle;">衛生福利部中央健康保險署-醫審及藥材組</td>
</tr>
<tr>
    <td>貢獻者-IG</td>
    <td>張佐安</td>
</tr>
<tr>
    <td>貢獻者-IG</td>
    <td>鄧嘉欣</td>
</tr>
<tr>
    <td>貢獻者-IG</td>
    <td colspan="2">醫藥品查驗中心(CDE)</td>
</tr>

</tbody>
</table>


#### Cross Version Analysis

{% capture cross-version-analysis %}{% include cross-version-analysis.xhtml %}{% endcapture %}{{ cross-version-analysis | remove: '<p>' | remove: '</p>'}}

#### IG Dependencies

This IG Contains the following dependencies on other IGs.

{% include dependency-table.xhtml %}

#### Global Profiles

{% include globals-table.xhtml %}

#### Copyrights

{% capture ip-statement %}{% include ip-statements.xhtml %}{% endcapture %}

{{ ip-statement | remove: '<p>' | remove: '</p>'}}

