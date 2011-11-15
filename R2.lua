module("extensions.R2", package.seeall)
extension = sgs.Package("R2")

renzhu=sgs.CreateTriggerSkill{
name="renzhu",
events=sgs.PhaseChange,
on_trigger=function(self,event,player,data)
	local room=player:getRoom()	
	local liubang=room:findPlayerBySkillName(self:objectName())
	if liubang:getPhase()==sgs.Player_Play then	    
		if(room:askForSkillInvoke(liubang,self:objectName()) ~=true) then return false end
			local target = room:askForPlayerChosen(liubang, room:getOtherPlayers(liubang), "@renzhu")
			local x = target:getHandcardNum()
            if(x == 0) then return false end	
            local to_exchange=target:wholeHandCards()  
            local to_exchange2= liubang:wholeHandCards()  
            room:moveCardTo(to_exchange,liubang, sgs.Player_Hand, true) 
            room:moveCardTo(to_exchange2,target, sgs.Player_Hand, true) 			
			local log=sgs.LogMessage()
			log.from =liubang
			log.type ="#renzhu"
		    log.arg  =target:getGeneralName()
			room:sendLog(log)
	end
	end,
}
dafeng=sgs.CreateTriggerSkill{
	name="dafeng$",
	events=sgs.CardUsed,
	priority=2,
	can_trigger=function(target)
	return true
	end,
	on_trigger=function(self,event,player,data)
	if event==sgs.CardUsed then 	    
		local use=data:toCardUse()
		local card = use.card
		local room=player:getRoom()
		local liubang=room:findPlayerBySkillName(self:objectName())
		if not use.from:getKingdom()=="shu" then return false end		
		if use.from:objectName()== liubang:objectName() then return  false end
		if not card:isNDTrick() then return false end		
	    if (room:askForChoice(player, self:objectName(), "agree+ignore") ~= "agree") then return false end
		if (room:askForSkillInvoke(liubang,self:objectName())~=true) then return false end
        use.from=liubang		
		local log=sgs.LogMessage()
		log.type ="#dafeng"
		log.from=liubang
		log.arg  =player:getGeneralName()
		log.arg2  =use.card:objectName()
		room:sendLog(log)
		data:setValue(use)
        return false		
	end
	end,
}

yunchou_card=sgs.CreateSkillCard{
name="yunchou_effect",
once=true,
will_throw=false,
filter=function(self,targets,to_select)
	if not to_select:hasFlag("yunchou_source") then return false
	else return true end
end,
on_effect=function(self,effect)
	effect.to:obtainCard(self);
end
}

yunchou_viewAsSkill=sgs.CreateViewAsSkill{
name="yunchou_viewAs",
n=1,
view_filter=function(self, selected, to_select)
	if to_select:isEquipped() then return false
	else return true end
end,
view_as=function(self, cards)
	if #cards==0 then return nil end
	local ayunchou_card=yunchou_card:clone()	
	ayunchou_card:addSubcard(cards[1])	
	return ayunchou_card
end,
enabled_at_play=function()
	--return true
	return false
end,
enabled_at_response=function(self,pattern)
	if pattern=="@yunchou" then return true
	else return false end
end
}

yunchou=sgs.CreateTriggerSkill{
	name="yunchou",
	events={sgs.TurnStart},
	view_as_skill=yunchou_viewAsSkill,
	priority=2,
	can_trigger=function(target)
	return true
	end,
	--frequency=sgs.Skill_Compulsory,
	on_trigger=function(self,event,player,data)
	if not event==sgs.TurnStart then return false end		
		local room=player:getRoom()
		local zhangliang=room:findPlayerBySkillName(self:objectName())
		if(player:objectName()==zhangliang:objectName()) then return false end
		if (room:askForSkillInvoke(zhangliang,self:objectName())~=true) then return false end
		local prompt="@@yunchou"
		room:setPlayerFlag(player,"yunchou_source")
		local card=room:askForUseCard(zhangliang,"@yunchou",prompt)
		room:setPlayerFlag(player,"-yunchou_source")
        if card then
			--room:setPlayerFlag(player,"-yunchou_source")		
			room:doGuanxing(zhangliang, room:getNCards(3), false)
			return false
		end
	end
}

mingzhe=sgs.CreateTriggerSkill{
	name="mingzhe",
	events={sgs.Predamaged},
	priority=3,
	frequency=sgs.Skill_Compulsory,
	on_trigger=function(self,event,player,data)
	if not event==sgs.Predamaged then return false end
		local damage=data:toDamage()
		local room=player:getRoom()
		local zhangliang=room:findPlayerBySkillName(self:objectName())
		--if (room:askForSkillInvoke(player,self:objectName())~=true) then return false end
		local x=0
		while x<damage.damage do
		   room:doGuanxing(player, room:getNCards(3), false)	
		   player:drawCards(1)
           x=x+1		   
		end
		return false
	end
}

yishan=sgs.CreateViewAsSkill{
name="yishan",
n=2,
view_filter=function(self, selected, to_select)
	if #selected ==0 then return not to_select:isEquipped() end
	if #selected == 1 then 
			local cc = selected[1]:getSuit()
			return (not to_select:isEquipped()) and to_select:getSuit() == cc
	else return false
	end	
end,
view_as=function(self, cards)
	if #cards==0 then return nil end	
	if #cards==2 then	
		local ys_card=sgs.Sanguosha:cloneCard("archery_attack",sgs.Card_NoSuit, 0)	
		ys_card:addSubcard(cards[1])	
		ys_card:addSubcard(cards[2])
		ys_card:setSkillName(self:objectName())
		return ys_card end	
end,
enabled_at_play=function()
	return true	
end,
enabled_at_response=function(self,pattern)	
	return false 
end
}


baijiang=sgs.CreateTriggerSkill{
	name="baijiang",
	events={sgs.PhaseChange},
	priority=2,
	--frequency=sgs.Skill_Compulsory,
	on_trigger=function(self,event,player,data)	
	if player:getMark("baijiangwaked")>0 then return false end
	if event==sgs.PhaseChange and player:getPhase()==sgs.Player_Start then 		
		local room=player:getRoom()
		if (player:getHp()==1) then			
			if player:getMark("baijiangwaked")<1 then
			local log=sgs.LogMessage()
			log.type ="#baijiang"
			log.from=player		
			room:sendLog(log)
			room:setPlayerMark(player,"baijiangwaked",1)
			room:loseMaxHp(player,2)
			end
			return false
		else return false
		end
	return false	
	end
	end
}

dianbing=sgs.CreateTriggerSkill{		
	name="dianbing",	
	priority=1,
	events={sgs.DrawNCards,sgs.PhaseChange}, 
	on_trigger=function(self,event,player,data)	
		if player:getMark("baijiangwaked")>=1 then 
		local room=player:getRoom()		
			if event==sgs.DrawNCards then 			
				data:setValue(data:toInt()+2)
				local log=sgs.LogMessage()
				log.type ="#dianbingdraw"
				log.from=player		
				room:sendLog(log)
				return false
			elseif (event==sgs.PhaseChange) and (player:getPhase()==sgs.Player_Discard) then							
				local x = player:getHp()
				local y = player:getHandcardNum()				
				if y-x>1 then 
					room:askForDiscard(player,"dianbing",y-x-1,false,false) 				
					return true
				else return false
				end			
			end	
		end
	end
}
liangdao=sgs.CreateTriggerSkill{
name="liangdao",
can_trigger=function(target)
return true
end,
events=sgs.PhaseChange,
on_trigger=function(self,event,player,data)
	local room=player:getRoom()	
	local xiaohe=room:findPlayerBySkillName(self:objectName())
	if player:getPhase()==sgs.Player_Finish then 	    
		--if(room:askForSkillInvoke(xiaohe,self:objectName()) ~=true) then return false end
			local x = player:getMaxHP()
			local y = player:getHandcardNum()
			if y<=1 then 
					if (room:askForSkillInvoke(xiaohe,self:objectName())~=true) then return false end
					local log=sgs.LogMessage()
					log.type ="#liangdao"
					log.from=player		
					room:sendLog(log)
					if (x-y<=5) then 
						player:drawCards(x-y)
					else player:drawCards(5) end
				else return false
			end			
	end
	end,
}
jiulv=sgs.CreateTriggerSkill{
	name="jiulv",
	events={sgs.CardEffected},
	--frequency=sgs.Skill_Frequent,
	on_trigger=function(self,event,player,data)
		local effect=data:toCardEffect()
		local room=player:getRoom()
		if not effect.card:inherits("Slash") then return end		
		if not room:askForSkillInvoke(player,self:objectName()) then return end
		local log=sgs.LogMessage()
		log.type ="#jiulv"
		log.arg  =player:getGeneralName()
		room:sendLog(log)
		local x=player:getLostHp()+1
		player:drawCards(x)
		room:askForDiscard(player,"jiulv",x,false,false) 
	end
}
zhuxin=sgs.CreateTriggerSkill{
	name="zhuxin",
	events={sgs.PhaseChange},
	priority=2,
	on_trigger = function(self,event,player,data)
	local room=player:getRoom()
	local log=sgs.LogMessage()
	log.from=player	
	if (event==sgs.PhaseChange) then
		if not player:hasSkill(self:objectName()) then return end	
		if player:getPhase()~=sgs.Player_Play then return end
		if not room:askForSkillInvoke(player,self:objectName()) then return end
			local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), "zhuxin")	
			while(target:getHandcardNum()==0) do
					target = room:askForPlayerChosen(player, room:getOtherPlayers(player), "zhuxin")
			end
			local card_id=room:askForCardChosen(target,target,"h",self:objectName())
			local card=sgs.Sanguosha:getCard(card_id)
			log.type = "#zhuxincard"
			log.arg2= card:getSuitString()
			log.arg = target:getGeneralName()
			room:sendLog(log)
			local suit=card:getSuitString()
			suit="."..suit:sub(1,1):upper()
			room:setPlayerFlag(player,"zhuxin_source")
			local zx=room:askForUseCard(player,suit,"@zhuxin:"..suit)
			if zx then 
					local damage=sgs.DamageStruct()
					damage.damage=1
					damage.from=player
					damage.to=target
					damage.nature=sgs.DamageStruct_Normal
					damage.chain=false					
					log.type = "#zhuxin"
					log.arg = target:getGeneralName()
					room:sendLog(log)
					room:damage(damage)
					room:setPlayerFlag(player,"-zhuxin_source")
			end
		end			
	end	
}

yanran=sgs.CreateTriggerSkill{		
	name      = "yanran",
	events={sgs.Predamage,sgs.PhaseChange}, 
	--priority=2,
	frequency=sgs.Skill_Compulsory,
	on_trigger=function(self,event,player,data)	
		local room=player:getRoom()	
		local lvzhi=room:findPlayerBySkillName(self:objectName())
		local log=sgs.LogMessage()
		log.from=lvzhi	
		if player:hasSkill(self:objectName()) then return end
		local to_discard=0
			if(event==sgs.Predamage) and (player:getPhase()==sgs.Player_Play)then
				local damage=data:toDamage()
				to_discard=to_discard+damage.damage
				--if not room:askForSkillInvoke(lvzhi,self:objectName()) then return end
				room:setPlayerFlag(player,"yanran_source")
				return false			
			elseif (event==sgs.PhaseChange) and (player:getPhase()==sgs.Player_Discard) then
					if not player:hasFlag("yanran_source") then return end
					--if not room:askForSkillInvoke(lvzhi,self:objectName()) then return end
					local x = player:getHp()
					local y = player:getHandcardNum()
					local z=(to_discard/2)+1					
					log.type = "#yanran"
					log.arg = player:getGeneralName()
					--log.arg2=sgs.qstring(to_discard)
					room:sendLog(log)
					if (y<=x) then room:askForDiscard(player,"yanran",z,false,false)
						room:setPlayerFlag(player,"-yanran_source")
						return true
					elseif(y-x<=z)  then room:askForDiscard(player,"yanran",z,false,false) 
						room:setPlayerFlag(player,"-yanran_source")
						return true
					elseif(y-x>z)  then return false
					end
					
			end
	end,
	can_trigger=function()
		return true
	end
}


qiji=sgs.CreateTriggerSkill{
	name="qiji",
	events={sgs.Predamaged},
	priority=3,
	--frequency=sgs.Skill_Compulsory,
	on_trigger=function(self,event,player,data)
	if not event==sgs.Predamaged then return false end
		local room=player:getRoom()		
		local chenping=room:findPlayerBySkillName(self:objectName())
		local damage=data:toDamage()
		if damage.damage==0 then return end
		if player:hasSkill(self:objectName())
		or damage.from:hasSkill(self:objectName())then return end
		if chenping:isKongcheng() 
		or damage.from:isKongcheng()
		then return end		
		if (room:askForSkillInvoke(chenping,self:objectName())~=true) then return false end
		if(room:askForDiscard(chenping,self:objectName(),1,false,false)) then --return end
			local card_id=room:askForCardChosen(chenping,damage.from,"ejh",self:objectName())
			room:moveCardTo(sgs.Sanguosha:getCard(card_id),chenping,sgs.Player_Hand,true)
			local target = room:askForPlayerChosen(chenping, room:getOtherPlayers(chenping), "qiji")
			room:obtainCard(target,card_id)			
		    return false
		end
	end,
	can_trigger=function()
		return true
	end,
}
taohui=sgs.CreateTriggerSkill{		
	name      = "taohui",
	events={sgs.Predamaged,sgs.PhaseChange}, 
	--priority=2,
	frequency=sgs.Skill_Compulsory,
	on_trigger=function(self,event,player,data)	
		local room=player:getRoom()			
		local log=sgs.LogMessage()
		log.from=player	
		log.type ="#taohui"
		if not player:hasSkill(self:objectName()) then return end
		if(event==sgs.Predamaged) then
			local damage=data:toDamage()
			local x=0
			room:sendLog(log)
			while x<damage.damage do
				player:drawCards(1)
				x=x+1
			end
			return false			
		elseif (event==sgs.PhaseChange) and (player:getPhase()==sgs.Player_Discard) then
			local y = player:getHandcardNum()
			local z = player:getLostHp()+player:getMaxHP()
			if (y>z) then room:askForDiscard(player,"SKILLNAME",y-z,false,false)
				return true
			else
				room:sendLog(log)
				return true					
			end
					
			end
	end,
}

meihuo=sgs.CreateTriggerSkill{
	name="meihuo",
	events=sgs.AskForRetrial,
	--frequency=sgs.Skill_Compulsory,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		local zhaofeiyan=room:findPlayerBySkillName(self:objectName())
		local judge=data:toJudge()			
		zhaofeiyan:setTag("Judge",data)		
		if (room:askForSkillInvoke(zhaofeiyan,self:objectName())~=true) then return false end			
		local target = room:askForPlayerChosen(zhaofeiyan, room:getOtherPlayers(player), self:objectName())		
		while (not target:getGeneral():isMale()) and (not target:isKongcheng())  do
			target = room:askForPlayerChosen(zhaofeiyan, room:getOtherPlayers(player), self:objectName())
		end			
		if target:isKongcheng() then return false end
		local card_id=room:askForCardChosen(zhaofeiyan,target,"h",self:objectName())		
		local card=sgs.Sanguosha:getCard(card_id)		
		target:obtainCard(judge.card)
		judge.card=card
		room:moveCardTo(judge.card,judge.who, sgs.Player_Special, true)
		local log=sgs.LogMessage()
		log.type = "#meihuo"
		log.from=zhaofeiyan
			--log.arg2= card:getSuitString()
		log.arg = target:getGeneralName()
		room:sendLog(log)			
		room:sendJudgeResult(judge)	
			--room:setPlayerFlag(zhaofeiyan,"-meihuo")			
		
		return true
	end,	
}

juewu=sgs.CreateTriggerSkill{
	name="juewu",
	events={sgs.CardUsed},	
	can_trigger=function()
	return true
	end,
	on_trigger=function(self,event,player,data)
		local use=data:toCardUse()
		local room=player:getRoom()			
		local zhaofeiyan=room:findPlayerBySkillName(self:objectName())
		local log=sgs.LogMessage()	
		log.from =zhaofeiyan
		if not (use.card:inherits("Slash") and use.to:contains(zhaofeiyan))then return end		
		if not room:askForSkillInvoke(zhaofeiyan,self:objectName()) then return end
		local x=1
		local y=0
		while (x) do
		if (room:askForDiscard(zhaofeiyan,self:objectName(),1,true,false)) then 
		y=y+1
		else break
		end
		end
		local z=0
		local sp=sgs.SPlayerList()
		while (z<=y) do
		local p = room:askForPlayerChosen(zhaofeiyan, room:getOtherPlayers(use.from), "juewu")
		sp:append(p)
		z=z+1
		end
		if(y>1) then 
		room:setEmotion(zhaofeiyan,"good")
		log.type ="#juewu"
		log.to=sp		
		room:sendLog(log)
		use.to:clear()
		use.to=sp
		data:setValue(use)
		elseif y==1 then
		log.type ="#juewu_failed"
		room:sendLog(log)
		sp:append(zhaofeiyan)		
		use.to:clear()
		use.to=sp
		data:setValue(use)
		end		
		return false		
	end
}


cifu_card=sgs.CreateSkillCard{
name="cifucard",
target_fixed=true,
will_throw=false,
on_use=function(self,room,source,targets)
	room:throwCard(self)
end
}

cifuvs=sgs.CreateViewAsSkill{
name="cifuvs",
n=1,
view_filter=function(self, selected, to_select)
	if to_select:isEquipped() then return false end
	if to_select:isBlack() then return true 
	else return false end	
end,
view_as=function(self, cards)
	if #cards==1 then 
	local acard=cifu_card:clone()
	acard:addSubcard(cards[1])
	acard:setSkillName("cifu")
	return acard end
end,
enabled_at_play=function()	
	return false
end,
enabled_at_response=function(self,pattern)
	if pattern=="@cifu" then return true
	else return false end
end
}

cifu=sgs.CreateTriggerSkill{
	name="cifu",
	events=sgs.Damaged,
	view_as_skill=cifuvs,
	can_trigger=function()
	return true
	end,
	on_trigger = function(self,event,player,data)
		local damage=data:toDamage()
		if not damage.card:inherits("Slash") then return end
		local room=player:getRoom()
		local simaxiangru=room:findPlayerBySkillName(self:objectName())
		if simaxiangru:isKongcheng() then return end
		if not room:askForSkillInvoke(simaxiangru,self:objectName()) then return end
		local card=room:askForUseCard(simaxiangru,"@cifu","@@cifu")		
        if card then		  
		   local log=sgs.LogMessage()
		   log.from =simaxiangru
		   log.type ="#cifu"
		   log.arg  =player:getGeneralName()
		   room:sendLog(log)
		   local recover=sgs.RecoverStruct()
		   recover.who=simaxiangru
		   recover.recover=1
		   room:recover(player,recover)
		end	
	end
}

qiuhuang_card=sgs.CreateSkillCard{
name="qiuhuangcard",
target_fixed=true,
will_throw=false,
on_use=function(self,room,source,targets)
	local sp=sgs.SPlayerList()
	for _,p in sgs.qlist(room:getAlivePlayers()) do
		if not p:getGeneral():isMale() then sp:append(p) end				
	end	
    if sp:isEmpty() then return end		
	local t=room:askForPlayerChosen(source, sp, "qiuhuang")
	room:moveCardTo(self,t, sgs.Player_Hand, true)
	if (room:askForChoice(t, self:objectName(), "recover+givecard") == recover) then 
	local recover=sgs.RecoverStruct()		   
		   recover.recover=1
		   recover.who=source
		   room:recover(t,recover)
		   recover.who=t
		   room:recover(source,recover)
	else
		source:drawCards(1)
	end	
	room:setPlayerFlag(source,"-qiuhuangf")
end
}

qiuhuangvs=sgs.CreateViewAsSkill{
name="qiuhuangvs",
n=1,
view_filter=function(self, selected, to_select)
	if to_select:isEquipped() then return false end
	if to_select:isRed() then return true 
	else return false end	
end,
view_as=function(self, cards)
	if #cards==1 then 
	local acard=qiuhuang_card:clone()
	acard:addSubcard(cards[1])
	acard:setSkillName("qiuhuang")
	return acard end
end,
enabled_at_play=function()
	if sgs.Self:hasFlag("qiuhuangf")then return true	
	else return false end
end,
enabled_at_response=function(self,pattern)
	return false 
end
}

qiuhuang=sgs.CreateTriggerSkill{
name="qiuhuang",
events=sgs.PhaseChange,
view_as_skill=qiuhuangvs,
on_trigger=function(self,event,player,data)
	if not (event==sgs.PhaseChange) then return end
	local room=player:getRoom()		
	if (player:getPhase()==sgs.Player_Play) then 	    
		room:setPlayerFlag(player,"qiuhuangf")
	elseif (player:getPhase()==sgs.Player_Finish) then
		room:setPlayerFlag(player,"-qiuhuangf")
	end
	end,
}


--刘邦
liubang = sgs.General(extension, "liubang", "shu")
liubang:addSkill(renzhu) 
liubang:addSkill(dafeng)
--张良
zhangliang = sgs.General(extension, "zhangliang", "shu",3)
zhangliang:addSkill(yunchou)
zhangliang:addSkill(mingzhe)
--韩信
hanxin = sgs.General(extension, "hanxin", "shu")
hanxin:addSkill(yishan) --仅视为万箭齐发 类似蛊惑的技能太复杂
hanxin:addSkill(baijiang)
hanxin:addSkill(dianbing)
--萧何
xiaohe = sgs.General(extension, "xiaohe", "shu",3)
xiaohe:addSkill(liangdao)
xiaohe:addSkill(jiulv)
--吕雉
lvzhi = sgs.General(extension, "lvzhi", "shu",3)
lvzhi:addSkill(zhuxin)
lvzhi:addSkill(yanran)
--陈平
chenping = sgs.General(extension, "chenping", "shu",3)
chenping:addSkill(qiji)  --不符合1血两牌的规律
chenping:addSkill(taohui)--同上  
--赵飞燕
zhaofeiyan = sgs.General(extension, "zhaofeiyan", "shu",3,false)
zhaofeiyan:addSkill(meihuo) --此处男性角色随机打出一张牌来干预判定
zhaofeiyan:addSkill(juewu)
--司马相如
simaxiangru = sgs.General(extension, "simaxiangru", "shu",3)
simaxiangru:addSkill(cifu)
simaxiangru:addSkill(qiuhuang)

sgs.LoadTranslationTable{
	["R2"] = "R2零件包",
	
	["liubang"] = "刘邦",
	["renzhu"]="人主",
	[":renzhu"]="出牌阶段,你可以指定一名角色,该角色将所有手牌与你交换,每阶段限用一次.",
	["#renzhu"]="由于%from的【人主】 %arg与之交换了所有手牌",	
	["dafeng"]="大风",	
	[":dafeng"]="<b>主公技</b>当其他蜀势力角色使用非延时锦囊时,(在结算前)可令你成为该锦囊的使用者(你可以拒绝).",	
	["#dafeng"]="%arg使用了【大风】，令%from成为了%arg2的使用者",
	["dafeng:agree"] = "让刘邦成为这张锦囊的使用者",
	["dafeng:ignore"] = "不发动大风",
	
	["zhangliang"] = "张良",
	["yunchou"] = "运筹",
	["yunchou_effect"]="运筹",
	["@yunchou"] = "运筹",
	["@@yunchou"] = "请使用一张手牌以运筹",
	[":yunchou"] = "任意其他角色回合开始阶段,你可以交给该角色一张手牌,然后观看牌堆顶的三张牌\
	将其中任意数量的牌以任意顺序置于牌堆顶,其余以任意顺序置于牌堆底.",
	["mingzhe"] = "明哲",
	[":mingzhe"] = "你每受到1点伤害,可以观看牌堆顶的三张牌,并调整其顺序,然后你摸一张牌。",
	
	["hanxin"] = "韩信",
	["yishan"] = "益善",
	[":yishan"] = "出牌阶段,你可以将两张相同花色的手牌当作任意基本牌或非延时锦囊使用或打出,每阶段限用一次",
	["baijiang"] = "拜将",
	[":baijiang"] = "<b>觉醒技</b>，回合开始阶段，若你的体力为1，你须减2点体力上限\
	并永久获得技能“点兵”（摸牌阶段，你可以额外摸两张牌，你的手牌上限+1）。",
	["#baijiang"] = "%from的觉醒技【拜将】被触发，【点兵】技能开始生效",
	["dianbing"] = "点兵",
	[":dianbing"] = "摸牌阶段，你可以额外摸两张牌，你的手牌上限始终+1",
	["#dianbingdraw"] = "%from的【点兵】被触发，摸牌阶段将额外摸2张牌",
	
	
	["xiaohe"] = "萧何",
	["liangdao"] = "粮道",
	[":liangdao"] = "任意角色的回合结束阶段,若其手牌数不超过一,你可以令该角色将手牌补至其体力上限的张数(最多补至五张)",
	["#liangdao"] = "由于【粮道】的效果，%from的手牌将补充至其体力上限的张数",
	["jiulv"] = "九律",
	[":jiulv"] = "当你成为【杀】的目标时,你可以摸X张牌,然后弃等量的手牌,X为你已损失的体力值+1",
	
	["lvzhi"] = "吕雉",
	["zhuxin"] = "诛心",
	[":zhuxin"] ="出牌阶段开始时,你可以指定一名角色展示一张手牌的花色\
然后你可以使用一张与展示牌相同花色的手牌,若如此做,视为你对其造成1点伤害\
★牌的花色展示仅会在游戏日志窗出现\
★若在其展示完毕你不能打出同花色的牌,则技能不会生效",
	["#zhuxin"]="%from的【诛心】成功生效，%arg将受到1点伤害",
	["#zhuxincard"]="由于%from的【诛心】,%arg展示了一张 %arg2 牌",
	["@zhuxin"] = "请弃掉一张与展示牌同花色的手牌",
	["yanran"] = "晏然",
	[":yanran"] = "<b>锁定技</b>,若其他角色在各自的回合中造成来源于该角色的伤害\
该角色弃牌阶段须至少弃X张牌,X为其本回合中所造成的伤害值的一半(向上取整)",	
	["#yanran"] = "%from的【晏然】被触发,%arg弃牌时将至少弃掉其在本回合造成伤害值的一半",
	
	["chenping"]="陈平",
	["qiji"] = "奇计",
	[":qiji"] = "每当其他角色受到伤害时,你可以弃一张手牌,从该角色或伤害来源处获得一张牌并立即交给除你以外的任一角色",
	["taohui"] = "韬晦",
	[":taohui"] = "<b>锁定技</b>,你每受到1点伤害,立即摸一张牌;你的手牌上限始终为<font color='red'>体力上限</font>+X,X为当前你已损失体力值",
	["#taohui"] = "%from的锁定技【<b><font color='yellow'>韬晦</font></b>】被触发",	
	
	["zhaofeiyan"]="赵飞燕",
	["meihuo"] = "魅惑",
	[":meihuo"] = "在任意角色的判定牌生效前,你可指定一名男性角色,抽其一张手牌替换之。",
	["#meihuo"] = "由于%from的魅惑 %arg更改了判定牌",
	["juewu"] = "绝舞",
	[":juewu"] = "当你成为【杀】的目标时,你可以弃X张牌\
然后指定任意X名未成为该【杀】目标的角色成为该【杀】的标.\
当X大于1时,视为你使用一张【闪】. (不得指定【杀】的使用者).",
	["#juewu"] = "%from的绝色舞姿感染了%to",
	["#juewu_failed"] = "%from的绝舞失效了",
	
	["simaxiangru"]="司马相如",
	["cifu_card"] = "辞赋",
	["cifu"] = "辞赋",
	[":cifu"] = "每当一名角色受到【杀】造成的一次伤害,你可以弃一张黑色手牌,令其回复1点体力",
	["cifuvs"] = "辞赋",
	["#cifu"] = "由于%from的【辞赋】,%arg将恢复1点体力",
	["@cifu"] = "辞赋",
	["@@cifu"] = "请打出一张黑色手牌",
	["qiuhuang"] = "求凰",
	[":qiuhuang"] = "出牌阶段,你可以给一名女性角色一张红色手牌,令其选择下列两项中的一项:1.你或她回复一点体力;2.给你一张黑色手牌.每阶段限用一次",
--这里的选项不应有或   还有给回的牌颜色限制无法实现	
	["qiuhuangcard:recover"]="你与他一起回复一点体力",
	["qiuhuangcard:givecard"]="让他摸1张牌",
	
	["designer:liubang"]="code:roxiel",	
	["designer:zhangliang"]="code:roxiel",
	["designer:hanxin"]="code:roxiel",
	["designer:xiaohe"]="code:roxiel",
	["designer:lvzhi"]="code:roxiel",
	["designer:chenping"]="code:roxiel",
	["designer:zhaofeiyan"]="code:roxiel",
	["designer:simaxiangru"]="code:roxiel",
}