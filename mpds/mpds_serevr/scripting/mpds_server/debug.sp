void _Debug()
{
  RegAdminCmd("sm_fix", cmd_fix, ADMFLAG_ROOT);
}

Action  cmd_fix(int client, int args)
{
  int num = GetEntityCount();
  ReplyToCommand(client, "最大实体数量:%d", num);

  return Plugin_Continue;
}
