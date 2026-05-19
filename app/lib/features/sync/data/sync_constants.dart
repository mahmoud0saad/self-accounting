/// Customization op types stored in [PendingSyncOps].
const kCustomizationOpTypes = {
  'create_user_category',
  'update_user_category',
  'delete_user_category',
  'upsert_user_category_override',
  'create_user_task',
  'update_user_task',
  'delete_user_task',
  'upsert_user_task_override',
};

bool isCustomizationOpType(String opType) =>
    kCustomizationOpTypes.contains(opType);
