import 'package:mb_rich_editor/mb_rich_editor.dart';

var smartBlockquote = SummernotePlugin.fromCode('smart-blockquote', """
    (function (factory) {
    if (typeof define === 'function' && define.amd) {
        define(['jquery'], factory);
    } else if (typeof module === 'object' && module.exports) {
        module.exports = factory(require('jquery'));
    } else {
        factory(window.jQuery);
    }
}(function (\$) {
    \$.extend(\$.summernote.plugins, {
        'smartBlockquoteExit': function (context) {
            var self = this;
            var ui = \$.summernote.ui;
            // Lấy các đối tượng core cần thiết
            var \$note = context.layoutInfo.note;
            var \$editor = context.layoutInfo.editor;
            var \$editable = context.layoutInfo.editable;

            this.events = {
                'summernote.keydown': function (we, e) {
                    // Chỉ xử lý phím Enter (không Shift)
                    if (e.keyCode === 13 && !e.shiftKey) {
                        
                        // Lấy vị trí con trỏ hiện tại
                        var range = context.invoke('editor.createRange');
                        var \$blockquote = \$(range.sc).closest('blockquote');

                        // Nếu đang nằm trong blockquote
                        if (\$blockquote.length > 0) {
                            
                            // Xác định block hiện tại (thường là thẻ p hoặc div)
                            var \$currentBlock = \$(range.sc).closest('p, div, h1, h2, h3, h4, h5, h6, li');
                            
                            // Kiểm tra dòng trống: Không có text và không có thẻ con (như img)
                            // Lưu ý: Summernote thường để <br> trong dòng trống, nên check text là đủ
                            var isEmpty = \$currentBlock.text().trim() === '' && 
                                          (\$currentBlock.find('img, span, div, input').length === 0);

                            // --- LOGIC THOÁT RA NGOÀI ---
                            if (isEmpty) {
                                e.preventDefault(); // Chặn việc tạo thêm dòng trống thứ 2

                                // 1. Xóa dòng trống hiện tại (cái dòng được tạo ra bởi cú Enter lần 1)
                                \$currentBlock.remove();

                                // 2. Tạo paragraph mới bên ngoài, ngay sau blockquote
                                var \$newPara = \$('<p><br/></p>');
                                \$blockquote.after(\$newPara);

                                // 3. Đưa con trỏ ra ngoài vào thẻ mới đó
                                var newRange = document.createRange();
                                var selection = window.getSelection();
                                newRange.setStart(\$newPara[0], 0);
                                newRange.collapse(true);
                                selection.removeAllRanges();
                                selection.addRange(newRange);
                                
                                // Lưu trạng thái để hỗ trợ Undo/Redo
                                context.invoke('editor.saveRange'); 
                            }
                            
                            // Nếu dòng KHÔNG trống:
                            // Ta KHÔNG làm gì cả (không preventDefault).
                            // Vì bạn đã set blockquoteBreakingLevel: 0, 
                            // nên Summernote sẽ tự động tạo dòng mới bên trong quote cho bạn.
                        }
                    }
                }
            };
        }
    });
}));
  """, options: {});
