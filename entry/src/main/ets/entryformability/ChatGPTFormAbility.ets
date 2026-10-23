import { formBindingData, FormExtensionAbility, formInfo } from '@kit.FormKit';
import { Want } from '@kit.AbilityKit';

export default class ChatGPTFormAbility extends FormExtensionAbility {
  onAddForm(_want: Want): formBindingData.FormBindingData {
    return formBindingData.createFormBindingData({
      title: 'ChatGPT',
      subtitle: '随时开始一段对话',
      prompt: '点击打开应用，继续与你的 AI 对话'
    });
  }

  onAcquireFormState(_want: Want): formInfo.FormState {
    return formInfo.FormState.READY;
  }

  onFormEvent(_formId: string, _message: string): void {}
  onRemoveForm(_formId: string): void {}
}
