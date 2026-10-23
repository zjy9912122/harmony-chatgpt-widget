import common from '@ohos.app.ability.common';
import Want from '@ohos.app.ability.Want';
import pasteboard from '@ohos.pasteboard';

const TAG = 'ShareService';

/**
 * 分享导出服务
 * 支持系统分享面板导出文本/JSON报告
 */
export class ShareService {
  private static instance: ShareService;

  private constructor() {}

  public static getInstance(): ShareService {
    if (!ShareService.instance) {
      ShareService.instance = new ShareService();
    }
    return ShareService.instance;
  }

  /**
   * 分享纯文本（调用系统分享面板）
   */
  async shareText(context: common.UIAbilityContext, text: string, title: string = '应用分析报告'): Promise<void> {
    try {
      const want: Want = {
        action: 'ohos.want.action.sendData',
        type: 'text/plain',
        parameters: {
          'title': title,
          'content': text
        }
      };
      await context.startAbility(want);
      console.info(TAG, '分享面板已唤起');
    } catch (error) {
      console.error(TAG, `分享失败: ${JSON.stringify(error)}`);
    }
  }

  /**
   * 分享JSON报告
   */
  async shareJSON(context: common.UIAbilityContext, jsonContent: string): Promise<void> {
    try {
      const want: Want = {
        action: 'ohos.want.action.sendData',
        type: 'application/json',
        parameters: {
          'title': '应用使用分析报告.json',
          'content': jsonContent
        }
      };
      await context.startAbility(want);
      console.info(TAG, 'JSON报告分享已唤起');
    } catch (error) {
      console.error(TAG, `JSON分享失败: ${JSON.stringify(error)}`);
    }
  }

  /**
   * 复制文本到剪贴板
   */
  async copyToClipboard(context: common.UIAbilityContext, text: string): Promise<boolean> {
    try {
      // 剪贴板不挂在 Context 上，要用独立的 @ohos.pasteboard 模块
      const pasteData: pasteboard.PasteData =
        pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text);
      const systemPasteboard: pasteboard.SystemPasteboard = pasteboard.getSystemPasteboard();
      await systemPasteboard.setData(pasteData);
      console.info(TAG, '文本已复制到剪贴板');
      return true;
    } catch (error) {
      console.error(TAG, `复制失败: ${JSON.stringify(error)}`);
      return false;
    }
  }
}
