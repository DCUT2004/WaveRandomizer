class WaveBossMessage extends Localmessage;

var(Message) localized string BossMessage, BossName;

static function string GetString(optional int Switch, optional PlayerReplicationInfo PRI1, optional PlayerReplicationInfo PRI2, optional Object OptionalObject)
{
	return default.BossMessage $ default.BossName;
}

defaultproperties
{
     BossMessage="Defeat the Boss!"
     bIsUnique=True
     bIsPartiallyUnique=True
     bFadeMessage=True
     Lifetime=7
     DrawColor=(B=0)
     StackMode=SM_Down
     PosY=0.150000
}
