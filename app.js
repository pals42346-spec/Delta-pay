const money=n=>"₹"+Math.round(n).toLocaleString("en-IN");
function calc(){let a=+amount.value||0,t=+term.value||0,r=+rate.value||0,i=a*r*t/1200;interest.textContent=money(i);maturity.textContent=money(a+i)}
function selectPlan(t,r){term.value=t;rate.value=r;document.getElementById("calculator").scrollIntoView({behavior:"smooth"});calc()}
function openModal(id){document.getElementById(id).classList.add("show")}
function closeModal(id){document.getElementById(id).classList.remove("show")}
function demo(){alert("Demo interface only — real account creation and money movement are not connected.")}
document.addEventListener("click",e=>{if(e.target.classList.contains("modal"))e.target.classList.remove("show")});calc();
