/proc/keywords_lookup(msg)

	//This is a list of words which are ignored by the parser when comparing message contents for names. MUST BE IN LOWER CASE!
	var/list/adminhelp_ignored_words = list("unknown","the","a","an","of","monkey","alien","as", "i")

	//explode the input msg into a list
	var/list/msglist = splittext(msg, " ")

	//generate keywords lookup
	var/list/surnames = list()
	var/list/forenames = list()
	var/list/ckeys = list()
	for(var/mob/M in mob_list)
		var/list/indexing = list(M.real_name, M.name)
		if(M.mind)
			indexing += M.mind.name

		for(var/string in indexing)
			var/list/L = splittext(string, " ")
			var/surname_found = 0
			//surnames
			for(var/i=L.len, i>=1, i--)
				var/word = ckey(L[i])
				if(word)
					surnames[word] = M
					surname_found = i
					break
			//forenames
			for(var/i=1, i<surname_found, i++)
				var/word = ckey(L[i])
				if(word)
					forenames[word] = M
			//ckeys
			ckeys[M.ckey] = M

	var/list/jobs = list()
	var/list/job_count = list()
	for(var/datum/mind/M in ticker.minds)
		var/T = lowertext(M.assigned_role)
		jobs[T] = M.current
		job_count[T]++ //count how many of this job was found so we only show link for singular jobs

	var/ai_found = 0
	msg = ""
	var/list/mobs_found = list()
	for(var/original_word in msglist)
		var/word = ckey(original_word)
		if(word)
			if(!(word in adminhelp_ignored_words))
				if(word == "ai")
					ai_found = 1
				else
					var/mob/found = ckeys[word]
					if(!found)
						found = surnames[word]
						if(!found)
							found = forenames[word]
					if(!found)
						var/T = lowertext(original_word)
						if(T == "cap") T = "captain"
						if(T == "hop") T = "head of personnel"
						if(T == "cmo") T = "chief medical officer"
						if(T == "ce")  T = "chief engineer"
						if(T == "hos") T = "head of security"
						if(T == "rd")  T = "research director"
						if(T == "qm")  T = "quartermaster"
						if(job_count[T] == 1) //skip jobs with multiple results
							found = jobs[T]
					if(found)
						if(!(found in mobs_found))
							mobs_found += found
							if(!ai_found && isAI(found))
								ai_found = 1
							msg += "[original_word]<font size='1' color='black'>(<A HREF='?_src_=holder;adminmoreinfo=\ref[found]'>?</A>|<A HREF='?_src_=holder;adminplayerobservefollow=\ref[found]'>F</A>)</font> "
							continue
		msg += "[original_word] "
	return msg


/proc/keywords_lookup_ai(mob/living/ML, msg)

	//This is a list of words which are ignored by the parser when comparing message contents for names. MUST BE IN LOWER CASE!
	var/list/adminhelp_ignored_words = list("unknown","the","a","an","of","monkey","alien","as", "i")

	//explode the input msg into a list
	var/list/msglist = splittext(msg, " ")

	//generate keywords lookup
	var/list/surnames = list()
	var/list/forenames = list()
	var/list/ckeys = list()
	for(var/mob/M in mob_list)
		var/list/indexing = list(M.real_name, M.name)
		if(M.mind)	indexing += M.mind.name

		for(var/string in indexing)
			var/list/L = splittext(string, " ")
			var/surname_found = 0
			//surnames
			for(var/i=L.len, i>=1, i--)
				var/word = ckey(L[i])
				if(word)
					surnames[word] = M
					surname_found = i
					break
			//forenames
			for(var/i=1, i<surname_found, i++)
				var/word = ckey(L[i])
				if(word)
					forenames[word] = M
			//ckeys
			ckeys[M.ckey] = M

	var/list/jobs = list()
	var/list/job_count = list()
	for(var/datum/mind/M in ticker.minds)
		var/T = lowertext(M.assigned_role)
		jobs[T] = M.current
		job_count[T]++ //count how many of this job was found so we only show link for singular jobs

	var/ai_found = 0
	msg = ""
	var/list/mobs_found = list()
	for(var/original_word in msglist)
		var/word = ckey(original_word)
		if(word)
			if(!(word in adminhelp_ignored_words))
				if(word == "ai")
					ai_found = 1
				else
					var/mob/found = ckeys[word]
					if(!found)
						found = surnames[word]
						if(!found)
							found = forenames[word]
					if(!found)
						var/T = lowertext(original_word)
						if(T == "cap") T = "captain"
						if(T == "hop") T = "head of personnel"
						if(T == "cmo") T = "chief medical officer"
						if(T == "ce")  T = "chief engineer"
						if(T == "hos") T = "head of security"
						if(T == "rd")  T = "research director"
						if(T == "qm")  T = "quartermaster"
						if(job_count[T] == 1) //skip jobs with multiple results
							found = jobs[T]
					if(found)
						if(!(found in mobs_found))
							mobs_found += found
							if(!ai_found && isAI(found))
								ai_found = 1
							msg += "[original_word]<font size='1' color='black'>(<A HREF=\"?src=\ref[ML];track=[found.name]\">T</A>)</font> "
							continue
		msg += "[original_word] "
	return msg

/proc/get_admin_counts(requiredflags = R_BAN)
	. = list("total" = 0, "noflags" = 0, "afk" = 0, "stealth" = 0, "present" = 0)
	for(var/client/X in admins)
		.["total"]++
		if(requiredflags != 0 && !check_rights_for(X, requiredflags))
			.["noflags"]++
		else if(X.is_afk())
			.["afk"]++
		else if(X.holder.fakekey)
			.["stealth"]++
		else
			.["present"]++

/proc/send2irc_adminless_only(source, msg, requiredflags = R_BAN)
	var/admin_number_total = 0		//Total number of admins
	var/admin_number_afk = 0		//Holds the number of admins who are afk
	var/admin_number_ignored = 0	//Holds the number of admins without +BAN (so admins who are not really admins)
	var/admin_number_decrease = 0	//Holds the number of admins with are afk, ignored or both
	for(var/client/X in admins)
		admin_number_total++;
		var/invalid = 0
		if(requiredflags != 0 && !check_rights_for(X, requiredflags))
			admin_number_ignored++
			invalid = 1
		if(X.is_afk())
			admin_number_afk++
			invalid = 1
		if(X.holder.fakekey)
			admin_number_ignored++
			invalid = 1
		if(invalid)
			admin_number_decrease++
	var/admin_number_present = admin_number_total - admin_number_decrease	//Number of admins who are neither afk nor invalid
	if(admin_number_present <= 0)
		if(!admin_number_afk && !admin_number_ignored)
			send2irc(source, "[msg] - No admins online")
		else
			send2irc(source, "[msg] - All admins AFK ([admin_number_afk]/[admin_number_total]) or skipped ([admin_number_ignored]/[admin_number_total])")
	return admin_number_present


/proc/send2irc(msg,msg2)
	if(config.useircbot)
		shell("python nudge.py [msg] [msg2]")
	return

/proc/send2otherserver(source,msg,type = "Ahelp")
	if(global.cross_allowed)
		var/list/message = list()
		message["message"] = "[source]: [msg]"
		message["source"] = "([config.cross_name])"
		message["key"] = global.comms_key
		message["crossmessage"] = type

		world.Export("[global.cross_address]?[list2params(message)]")