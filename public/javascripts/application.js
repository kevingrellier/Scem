// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults


function remove_field(element, item) {
    element.up(item).remove();
}

    document.observe("dom:loaded", function() { 

        // the element in which we will observe all clicks and capture
        // ones originating from pagination links
        var container = $(document.body)
        if (container) {
            var spinnerImg = new Element('img', { src: '/images/spinner.gif', 'class': 'spinner' });

            container.observe('click', function(e) {
                var el = e.element()
                if (el.match('.pagination a')) {
                    el.up('.pagination').insert(spinnerImg)
                    new Ajax.Request(el.href, {
                        method: 'get'
                    })
                    e.stop()
                }
           })
        }
        
    })



