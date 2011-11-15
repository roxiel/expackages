module("extensions.roxiel", package.seeall)
extension = sgs.Package("roxiel")

zhiyong=sgs.CreateTriggerSkill{
name="zhiyong",
events=sgs.Predamage,
frequency=sgs.Skill_Compulsory,
on_trigger=function(self,event,player,data)
	local room=player:getRoom()
	local damage=data:toDamage()
	local caozhen=room:findPlayerBySkillName("zhiyong")
	if not damage.from==caozhen then return false end
	if(room:askForSkillInvoke(caozhen,self:objectName()) ~=true) then return false end
		local log=sgs.LogMessage()
		log.from =player
		log.type ="#zhiyong"
		log.arg  =damage.to:getGeneralName()		
		local judge=sgs.JudgeStruct()
        judge.pattern=sgs.QRegExp("(.*):(club):(.*)")
        judge.good=true
        judge.reason="zhiyong"
        judge.who=caozhen
        room:judge(judge)
						if judge:isGood() then
                                room:setEmotion(caozhen, "good")
								room:setEmotion(damage.to, "bad")
								room:sendLog(log)
								room:loseHp(damage.to,2)
								return true
						else 
						log.type ="#zhiyongfailed"
						room:sendLog(log)
						return true		
                        end		
	end,
}
pianzhi=sgs.CreateTriggerSkill{
	name="pianzhi",
	events=sgs.CardLost,
	on_trigger = function(self,event,player,data)
		local room=player:getRoom()
		local move=data:toCardMove()

		if not move.to then return end
		if move.from:objectName()==move.to:objectName() then return end
		if move.to_place==sgs.Player_Judging then return end

		if move.to:hasSkill(self:objectName()) and
		(move.from_place==sgs.Player_Hand or
		 move.from_place==sgs.Player_Judging or
		 move.from_place==sgs.Player_Equip) then
        
			if not room:askForSkillInvoke(move.to,self:objectName()) then return false end 
			if(room:askForDiscard(move.to,self:objectName(),1,false,false)) then
				local damage=sgs.DamageStruct()
				damage.damage=1
				damage.from=move.to
				damage.to=move.from
				damage.nature=sgs.DamageStruct_Normal
				damage.chain=false
				local log=sgs.LogMessage()
				log.type = "#pianzhi"
				log.arg = move.from:getGeneralName()
				room:sendLog(log);
				room:damage(damage)
			end

		 end

	end,

	can_trigger=function()
		return true
	end
}

dizhu=sgs.CreateTriggerSkill{		
	name      = "dizhu",
	events=sgs.PhaseChange, 
	frequency=sgs.Skill_Compulsory,
	on_trigger=function(self,event,player,data)	
		local room=player:getRoom()	
			if (event==sgs.PhaseChange) and (player:getPhase()==sgs.Player_Discard) then							
				local x = player:getHp()
				local y = player:getHandcardNum()				
				if y-x>3 then room:askForDiscard(player,"dianbing",y-x-3,false,false) 				
				return true
				else return true
				end			
			end		
	end
}

dubo=sgs.CreateTriggerSkill{
	name="dubo",
	events={sgs.CardUsed,sgs.PhaseChange},
	priority=2,
	on_trigger=function(self,event,player,data)	
	local room=player:getRoom()
	local doudizhu=room:findPlayerBySkillName(self:objectName())	
	--local cards={}
	local log=sgs.LogMessage()
	log.from=doudizhu
	if (event==sgs.CardUsed) and (player:getPhase()==sgs.Player_Play) then 	    
		local use=data:toCardUse()
		local card = use.card				
		if use.from:objectName()~= doudizhu:objectName() then return  false end	
		if  player:getPile("dubocards"):length() == 3 then return false end
		if  player:hasFlag("dubo_source")then return false end
		if (room:askForSkillInvoke(doudizhu,self:objectName())~=true) then return false end
        --table.insert(cards,card:getNumber())
		room:setPlayerFlag(player,"dubo_source")
		room:useCard(use)
		player:addToPile("dubocards",card:getId())
		room:setPlayerFlag(player,"-dubo_source")
		local log=sgs.LogMessage()
		log.type ="#dubo"		
		log.arg  =card:getNumberString()		
		room:sendLog(log)		
		return true		
	elseif (event==sgs.PhaseChange) and (player:getPhase()==sgs.Player_Finish) then
	    if  player:getPile("dubocards"):length() == 3 then
			if (room:askForSkillInvoke(doudizhu,self:objectName())~=true) then return false end
				local third=sgs.Sanguosha:getCard(doudizhu:getPile("dubocards"):at(2)):getNumber()
				local second=sgs.Sanguosha:getCard(doudizhu:getPile("dubocards"):at(1)):getNumber()
				local first=sgs.Sanguosha:getCard(doudizhu:getPile("dubocards"):at(0)):getNumber()
				if (((third-second==1) and (second-first==1))  
				or ((first-second==1) and (second-third==1))		
				or ((second-first==2) and (second-third==1))
				or ((first-second==2) and (third-second==2))
				or ((second-first==1) and (second-third==2)) )then			
					log.type ="#shunzifinish"							      		
					room:sendLog(log)
					local x=0
					while x<3 do
					local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), "shunzi")
					target:turnOver()
					x=x+1
					end
				elseif((third==second) and (third==first)) then
					log.type ="#baozifinish"							      		
					room:sendLog(log)
					local x=0
					while x<2 do
					local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), "shunzi")
					room:loseHp(target,1)
					x=x+1
					end				
				end	
					for _,cid in sgs.qlist(player:getPile("dubocards")) do
					room:throwCard(cid)
					end
		end	
	end		
				
end	
}

shuaixi=sgs.CreateTriggerSkill{
	name="shuaixi",
	events={sgs.CardLost,sgs.Predamage},
	frequency=sgs.Skill_Compulsory,
	on_trigger = function(self,event,player,data)
	local room=player:getRoom()
	local log=sgs.LogMessage()
	local caojie=room:findPlayerBySkillName(self:objectName())
	log.from=caojie
	if (event==sgs.CardLost) then		
		local move=data:toCardMove()
		--if not move.to then return end
		--if move.to==caojie then return end
		if move.from:objectName()==move.to:objectName() then return end
		if move.to_place==sgs.Player_Judging then return end
		if move.from:hasSkill(self:objectName()) and
		(move.from_place==sgs.Player_Hand or
		 move.from_place==sgs.Player_Judging or
		 move.from_place==sgs.Player_Equip) then			
				room:throwCard(move.card_id)								
				log.type = "#shuaiximove"
				log.arg = move.to:getGeneralName()
				room:sendLog(log)			
			return true
		 end
	elseif (event==sgs.Predamage) then	 
	       local damage=data:toDamage()
		   if damage.from==caojie then return end
		   if not damage.to:hasSkill(self:objectName()) then return end
		   local x=damage.damage
		   log.type = "#shuaixidamage"
		   log.arg = damage.from:getGeneralName()
		   room:sendLog(log)
		   room:loseHp(damage.to,x)
		   return true
	end
	end,
	can_trigger=function()
		return true
	end
}



xingyi=sgs.CreateTriggerSkill{
	name="xingyi",
	events=sgs.HpLost,
	priority=2,
	--frequency=sgs.Skill_Frequent,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		local lost=data:toInt()	
		if (room:askForSkillInvoke(player,self:objectName())~=true) then return false end
		local log=sgs.LogMessage()
		local x=0
		while x<lost do
			local cardid=room:getNCards(1)
			--room:showCard(player,card)			
			local card=sgs.Sanguosha:getCard(cardid:first())			
			if (card:getSuit()==sgs.Card_Spade) then
			    room:throwCard(cardid:first())
  			else player:addToPile("aid",cardid:first()) 				
				 log.from =player
				 log.type ="#xingyi"
				 log.arg  =card:objectName()
				 log.arg2  =card:getSuitString()
				 room:sendLog(log)
				 x=x+1
			end	
		end
		return false
	end,
}

shiyao=sgs.CreateTriggerSkill{
	name="shiyao",
	events=sgs.HpRecover,
	priority=2,
	--frequency=sgs.Skill_Frequent,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		local recover=data:toRecover()
		local caojie=room:findPlayerBySkillName(self:objectName())
		if player:hasFlag("shiyao_source") then return end
		if (room:askForSkillInvoke(caojie,self:objectName())~=true) then return false end
		room:setPlayerFlag(player,"shiyao_source")
		while (caojie:getPile("aid"):length()>0) do
			room:throwCard(caojie:getPile("aid"):first())
			local log=sgs.LogMessage()	
			log.from =caojie		
			local judge=sgs.JudgeStruct()
			judge.pattern=sgs.QRegExp("(.*):(.*):(.*)")
			judge.good=true
			judge.reason="shiyao"
			judge.who=caojie
			room:judge(judge)					
			local card=judge.card			
			if (card:isRed()) then			   
				 recover.recover=1
				 log.type ="#shiyao1"
				 log.arg  =player:getGeneralName()				 
				 room:sendLog(log)
				 room:recover(player,recover)
				 --data:setValue(recover)
				 
			elseif(card:isBlack()) then
			caojie:obtainCard(card)	
			log.type ="#shiyao2"
		    log.arg  =card:objectName()				 
		    room:sendLog(log)
			room:setPlayerFlag(player,"-shiyao_source")
			break
			end	
		end			
		return false
	end,
	can_trigger=function()
		return true
	end
}


caozhen = sgs.General(extension, "caozhen", "wei")
caozhen:addSkill(zhiyong) 
liufeng = sgs.General(extension, "liufeng", "shu")
liufeng:addSkill(pianzhi) 

siyeliuyue = sgs.General(extension, "siyeliuyue", "qun",3)
siyeliuyue:addSkill(dizhu)
siyeliuyue:addSkill(dubo)

caojie = sgs.General(extension, "caojie", "qun",3,false)
caojie:addSkill(shuaixi)
caojie:addSkill(xingyi)
caojie:addSkill(shiyao)

sgs.LoadTranslationTable{
	["roxiel"] = "R零件包",
	["caozhen"] = "曹真",
	["zhiyong"]="鸷勇",
	[":zhiyong"]="你每对一名角色造成伤害时，可阻止此伤害并进行一次判定，若为梅花，目标角色流失2点体力",
	["#zhiyong"]="由于%from的【鸷勇】 %arg此次受到的伤害无效，但会流失两点体力",
	["#zhiyongfailed"]="%from【鸷勇】失败了 %arg此次不会受到伤害",	
	["liufeng"] = "刘封",
	["pianzhi"]="偏执",
	[":pianzhi"]="每当你从其他角色处获得牌，你可以弃一张手牌，视为对该角色造成1点伤害。",
	["#pianzhi"]="由于%from的【偏执】 %arg将受到1点伤害",
	["~caozhen"]="持盈守位，劳谦其德",
	["~liufeng"]="恨不用孟子度之言",
	
	["siyeliuyue"]="似夜流月",
	["dizhu"]="地主",
	[":dizhu"]="<b>锁定技</b>,你的手牌上限始终+3",
	["dubo"]="赌博",
	[":dubo"]="出牌阶段,你每打出一张牌可以在其结算后放入【扑克区】,回合结束时：\
若你的【扑克区】的牌成为一组【顺子】你可以指定最多3名角色将武将牌翻面,目标可重复\
若你的【扑克区】的牌成为一组【豹子】你可以指定最多2名角色流失1点体力,目标可重复\
★【扑克区】的牌可以打乱顺序,但只要是顺子或豹子就会生效\
★出牌阶段若扑克区区已经有3张牌后,将不能再把牌放入顺子区",
	["#dubo"]="%from企图赌一把大的，现在打出了%arg",
	["dubocards"]="◇扑克区◇",	
	["#shunzifinish"]="%from成功打出了一副顺子牌，它可以依次指定3名角色武将牌翻面",
	["#baozifinish"]="%from成功打出了一副豹子牌，它可以依次指定2名角色流失1点体力",
	
	["caojie"]="曹节",
	["shuaixi"]="摔玺",
	[":shuaixi"]="<b>锁定技</b>,其他角色获得你的牌后将立即弃置该牌，且你受到的伤害均改为体力流失。",
	["#shuaiximove"]="%from的锁定技【摔玺】被触发,%arg将立即弃置刚才获得的牌",
	["#shuaixidamage"]="%from的锁定技【摔玺】被触发,%arg对其的伤害将转换为体力流失",
	["xingyi"]="行医",
	[":xingyi"]="<b>锁定技</b>,你每流失一点体力可以翻开牌堆顶一张牌,若不为黑桃,则将其置于你的武将牌上称为“药”。",
	["#xingyi"]="%from的【行医】被触发,牌堆顶上的%arg2%arg被炼成了【药】",
	["aid"]="【药】",
	["shiyao"]="施药",
	[":shiyao"]="当任意角色回复体力时，你弃一张药，进行一次判定\
结果若为红色，则你可以令该角色额外回复1点体力\
若为黑色，则你可以将这张【药】其收入手牌。",
    ["#shiyao1"]="由于%from的【施药】,%arg将额外回复1点体力",
	["#shiyao2"]="%from【施药】结束,将判定牌%arg拿走了",
	
	
	
	["designer:caozhen"]="roxiel",
	["designer:liufeng"]="roxiel",	
	["designer:doudizhu"]="【群】皇叔,code:roxiel",
	["designer:caojie"]="超人的咸鸭蛋,code:roxiel",
}