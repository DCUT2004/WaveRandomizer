class WaveRandomizedMessage extends Localmessage
	config(satoreMonsterPack);

var(Message) config localized string WaveRandomizedMessage, Wave1Message, Wave2Message, Wave3Message, Wave4Message, Wave5Message, Wave6Message, Wave7Message, Wave8Message, Wave9Message, Wave10Message, Wave11Message, Wave12Message, Wave13Message, Wave14Message, Wave15Message, Wave16Message, BrutalWaveMessage;

static function string GetString(optional int Switch, optional PlayerReplicationInfo PRI1, optional PlayerReplicationInfo PRI2, optional Object OptionalObject)
{
	if (Switch == 1)
		return default.Wave1Message;
	else if (Switch == 2)
		return default.Wave2Message;
	else if (Switch == 3)
		return default.Wave3Message;
	else if (Switch == 4)
		return default.Wave4Message;
	else if (Switch == 5)
		return default.Wave5Message;
	else if (Switch == 6)
		return default.Wave6Message;
	else if (Switch == 7)
		return default.Wave7Message;
	else if (Switch == 8)
		return default.Wave8Message;
	else if (Switch == 9)
		return default.Wave9Message;
	else if (Switch == 10)
		return default.Wave10Message;
	else if (Switch == 11)
		return default.Wave11Message;
	else if (Switch == 12)
		return default.Wave12Message;
	else if (Switch == 13)
		return default.Wave13Message;
	else if (Switch == 14)
		return default.Wave14Message;
	else if (Switch == 15)
		return default.Wave15Message;
	else if (Switch == 16)
		return default.Wave16Message;
	else if (Switch == 100)
		return default.BrutalWaveMessage;
	else
		return default.WaveRandomizedMessage;
}

defaultproperties
{
     bIsUnique=True
     bIsPartiallyUnique=True
     bFadeMessage=True
     Lifetime=7
     DrawColor=(B=0)
     StackMode=SM_Down
     PosY=0.150000
}
