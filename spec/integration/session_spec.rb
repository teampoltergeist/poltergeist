require 'spec_helper'

skip = [:modals]
skip << :windows if ENV['TRAVIS']
Capybara::SpecHelper.run_specs TestSessions::Poltergeist, 'Poltergeist', capybara_skip: skip

describe Capybara::Session do
  context 'with poltergeist driver' do
    before do
      @session = TestSessions::Poltergeist
    end

    describe Capybara::Poltergeist::Node do
      it 'raises an error if the element has been removed from the DOM' do
        @session.visit('/poltergeist/with_js')
        node = @session.find(:css, '#remove_me')
        expect(node.text).to eq('Remove me')
        @session.find(:css, '#remove').click
        expect { node.text }.to raise_error(Capybara::Poltergeist::ObsoleteNode)
      end

      it 'raises an error if the element was on a previous page' do
        @session.visit('/poltergeist/index')
        node = @session.find('.//a')
        @session.execute_script "window.location = 'about:blank'"
        expect { node.text }.to raise_error(Capybara::Poltergeist::ObsoleteNode)
      end

      it 'raises an error if the element is not visible' do
        @session.visit('/poltergeist/index')
        @session.execute_script "document.querySelector('a[href=js_redirect]').style.display = 'none'"
        expect { @session.click_link 'JS redirect' }.to raise_error(Capybara::ElementNotFound)
      end

      it 'hovers an element' do
        @session.visit('/poltergeist/with_js')
        expect(@session.find(:css, '#hidden_link span', visible: false)).to_not be_visible
        @session.find(:css, '#hidden_link').hover
        expect(@session.find(:css, '#hidden_link span')).to be_visible
      end

      it 'hovers an element before clicking it' do
        @session.visit('/poltergeist/with_js')
        @session.click_link 'Hidden link'
        expect(@session.current_path).to eq('/')
      end

      it 'does not raise error when asserting svg elements with a count that is not what is in the dom' do
        @session.visit('/poltergeist/with_js')
        expect { @session.has_css?('svg circle', count: 2) }.to_not raise_error
        expect(@session).to_not have_css('svg circle', count: 2)
      end

      context 'when someone (*cough* prototype *cough*) messes with Array#toJSON' do
        before do
          @session.visit('/poltergeist/index')
          array_munge = <<-EOS
          Array.prototype.toJSON = function() {
            return "ohai";
          }
          EOS
          @session.execute_script array_munge
        end

        it 'gives a proper error' do
          expect { @session.find(:css, 'username') }.to raise_error(Capybara::ElementNotFound)
        end
      end

      context 'when the element is not in the viewport' do
        before do
          @session.visit('/poltergeist/with_js')
        end

        it 'raises a MouseEventFailed error' do
          expect { @session.click_link('O hai') }.to raise_error(Capybara::Poltergeist::MouseEventFailed)
        end

        context 'and is then brought in' do
          before do
            @session.execute_script "$('#off-the-left').animate({left: '10'});"
            Capybara.default_wait_time = 1 #we need capybara to retry until animation finished
          end

          it 'clicks properly' do
            expect { @session.click_link 'O hai' }.to_not raise_error
          end

          after do
            Capybara.default_wait_time = 0
          end
        end
      end
    end

    context 'when the element is not in the viewport of parent element' do
      before do
        @session.visit('/poltergeist/scroll')
      end

      it 'scrolls into view' do
        @session.click_link 'Link outside viewport'
        expect(@session.current_path).to eq('/')
      end
    end

    describe 'Node#select' do
      before do
        @session.visit('/poltergeist/with_js')
        @session.find(:select, 'browser').find(:option, 'Safari').select_option
      end

      it 'fires the focus event' do
        expect(@session.find(:css, '#changes_on_focus').text).to eq('PhantomJS')
      end

      it 'fire the change event' do
        expect(@session.find(:css, '#changes').text).to eq('Safari')
      end

      it 'fires the blur event' do
        expect(@session.find(:css, '#changes_on_blur').text).to eq('Safari')
      end

      it 'fires the change event with the correct target' do
        expect(@session.find(:css, '#target_on_select').text).to eq('SELECT')
      end
    end

    describe 'Node#set' do
      before do
        @session.visit('/poltergeist/with_js')
        @session.find(:css, '#change_me').set('Hello!')
      end

      it 'fires the change event' do
        expect(@session.find(:css, '#changes').text).to eq('Hello!')
      end

      it 'fires the input event' do
        expect(@session.find(:css, '#changes_on_input').text).to eq('Hello!')
      end

      it 'accepts numbers in a maxlength field' do
        element = @session.find(:css, '#change_me_maxlength')
        element.set 100
        expect(element.value).to eq('100')
      end

      it 'accepts negatives in a number field' do
        element = @session.find(:css, '#change_me_number')
        element.set -100
        expect(element.value).to eq('-100')
      end

      it 'fires the keydown event' do
        expect(@session.find(:css, '#changes_on_keydown').text).to eq('6')
      end

      it 'fires the keyup event' do
        expect(@session.find(:css, '#changes_on_keyup').text).to eq('6')
      end

      it 'fires the keypress event' do
        expect(@session.find(:css, '#changes_on_keypress').text).to eq('6')
      end

      it 'fires the focus event' do
        expect(@session.find(:css, '#changes_on_focus').text).to eq('Focus')
      end

      it 'fires the blur event' do
        expect(@session.find(:css, '#changes_on_blur').text).to eq('Blur')
      end

      it 'fires the keydown event before the value is updated' do
        expect(@session.find(:css, '#value_on_keydown').text).to eq('Hello')
      end

      it 'fires the keyup event after the value is updated' do
        expect(@session.find(:css, '#value_on_keyup').text).to eq('Hello!')
      end

      it 'clears the input before setting the new value' do
        element = @session.find(:css, '#change_me')
        element.set ''
        expect(element.value).to eq('')
      end

      it 'supports special characters' do
        element = @session.find(:css, '#change_me')
        element.set '$52.00'
        expect(element.value).to eq('$52.00')
      end

      it 'attaches a file when passed a Pathname' do
        filename = Pathname.new('spec/tmp/a_test_pathname').expand_path
        File.open(filename, 'w') { |f| f.write('text') }

        element = @session.find(:css, '#change_me_file')
        element.set(filename)
        expect(element.value).to eq('C:\fakepath\a_test_pathname')
      end
    end

    it 'has no trouble clicking elements when the size of a document changes' do
      @session.visit('/poltergeist/long_page')
      @session.find(:css, '#penultimate').click
      @session.execute_script <<-JS
        el = document.getElementById('penultimate')
        el.parentNode.removeChild(el)
      JS
      @session.click_link('Phasellus blandit velit')
      expect(@session).to have_content('Hello')
    end

    it 'handles clicks where the target is in view, but the document is smaller than the viewport' do
      @session.visit '/poltergeist/simple'
      @session.click_link 'Link'
      expect(@session).to have_content('Hello world')
    end

    it 'handles clicks where a parent element has a border' do
      @session.visit '/poltergeist/table'
      @session.click_link 'Link'
      expect(@session).to have_content('Hello world')
    end

    it 'handles window.confirm(), returning true unconditionally' do
      @session.visit '/'
      expect(@session.evaluate_script("window.confirm('foo')")).to be true
    end

    it 'handles window.prompt(), returning the default value or null' do
      @session.visit '/'
      expect(@session.evaluate_script('window.prompt()')).to be_nil
      expect(@session.evaluate_script("window.prompt('foo', 'default')")).to eq('default')
    end

    it 'handles evaluate_script values properly' do
      expect(@session.evaluate_script('null')).to be_nil
      expect(@session.evaluate_script('false')).to be false
      expect(@session.evaluate_script('true')).to be true
      expect(@session.evaluate_script("{foo: 'bar'}")).to eq({'foo' => 'bar'})
    end

    it 'synchronises page loads properly' do
      @session.visit '/poltergeist/index'
      @session.click_link 'JS redirect'
      sleep 0.1
      expect(@session.html).to include('Hello world')
    end

    context 'click tests' do
      before do
        @session.visit '/poltergeist/click_test'
      end

      after do
        @session.driver.resize(1024, 768)
      end

      it 'scrolls around so that elements can be clicked' do
        @session.driver.resize(200, 200)
        log = @session.find(:css, '#log')

        instructions = %w(one four one two three)
        instructions.each do |instruction, i|
          @session.find(:css, "##{instruction}").click
          expect(log.text).to eq(instruction)
        end
      end

      # See https://github.com/teampoltergeist/poltergeist/issues/60
      it 'fixes some weird layout issue that we are not entirely sure about the reason for' do
        @session.visit '/poltergeist/datepicker'
        @session.find(:css, '#datepicker').set('2012-05-11')
        @session.click_link 'some link'
      end

      context 'with #two overlapping #one' do
        before do
          @session.execute_script <<-JS
            var two = document.getElementById('two')
            two.style.position = 'absolute'
            two.style.left     = '0px'
            two.style.top      = '0px'
          JS
        end

        it 'detects if an element is obscured when clicking' do
          expect {
            @session.find(:css, '#one').click
          }.to raise_error(Capybara::Poltergeist::MouseEventFailed)

          begin
            @session.find(:css, '#one').click
          rescue => error
            expect(error.selector).to eq('html body div#two.box')
            expect(error.message).to include('[200, 200]')
          end
        end

        it 'clicks in the centre of an element' do
          begin
            @session.find(:css, '#one').click
          rescue => error
            expect(error.position).to eq([200, 200])
          end
        end

        it 'clicks in the centre of an element within the viewport, if part is outside the viewport' do
          @session.driver.resize(200, 200)

          begin
            @session.find(:css, '#one').click
          rescue => error
            expect(error.position.first).to eq(150)
          end
        end
      end

      it 'can evaluate a statement ending with a semicolon' do
        expect(@session.evaluate_script('3;')).to eq(3)
      end
    end

    context 'double click tests' do
      before do
        @session.visit '/poltergeist/double_click_test'
      end

      it 'double clicks properly' do
        @session.driver.resize(200, 200)
        log = @session.find(:css, '#log')

        instructions = %w(one four one two three)
        instructions.each do |instruction, i|
          @session.find(:css, "##{instruction}").base.double_click
          expect(log.text).to eq(instruction)
        end
      end
    end

    context 'status code support', status_code_support: true do
      it 'determines status code when an user goes to a page by using a link on it' do
        @session.visit '/poltergeist/with_different_resources'

        @session.click_link 'Go to 500'

        expect(@session.status_code).to eq(500)
      end

      it 'determines properly status code when an user goes through a few pages' do
        @session.visit '/poltergeist/with_different_resources'

        @session.click_link 'Go to 201'
        @session.click_link 'Do redirect'
        @session.click_link 'Go to 402'

        expect(@session.status_code).to eq(402)
      end
    end

    it 'ignores cyclic structure errors in evaluate_script' do
      code = <<-JS
        (function() {
          var a = {}
          a.a = a
          return a
        })()
      JS
      expect(@session.evaluate_script(code)).to eq('(cyclic structure)')
    end

    it 'returns BR as a space in #text' do
      @session.visit '/poltergeist/simple'
      expect(@session.find(:css, '#break').text).to eq('Foo Bar')
    end

    it 'handles hash changes' do
      @session.visit '/#omg'
      expect(@session.current_url).to match(/\/#omg$/)
      @session.execute_script <<-JS
        window.onhashchange = function() { window.last_hashchange = window.location.hash }
      JS
      @session.visit '/#foo'
      expect(@session.current_url).to match(/\/#foo$/)
      expect(@session.evaluate_script('window.last_hashchange')).to eq('#foo')
    end

    context 'current_url' do
      let(:request_uri) { URI.parse(@session.current_url).request_uri }

      it 'supports whitespace characters' do
        @session.visit '/poltergeist/arbitrary_path/200/foo%20bar%20baz'
        expect(@session.current_path).to eq('/poltergeist/arbitrary_path/200/foo%20bar%20baz')
      end

      it 'supports escaped characters' do
        @session.visit '/poltergeist/arbitrary_path/200/foo?a%5Bb%5D=c'
        expect(request_uri).to eq('/poltergeist/arbitrary_path/200/foo?a%5Bb%5D=c')
      end

      it 'supports allowed characters' do
        @session.visit '/poltergeist/arbitrary_path/200/foo?a[b]=c'
        expect(request_uri).to eq('/poltergeist/arbitrary_path/200/foo?a%5Bb%5D=c')
      end

      it 'supports url in parameter' do
        @session.visit "/poltergeist/arbitrary_path/200/foo%20asd?a=http://example.com/asd%20asd"
        expect(request_uri).to eq('/poltergeist/arbitrary_path/200/foo%20asd?a=http://example.com/asd%20asd')
      end

      it 'supports restricted characters " []:/+&="' do
        @session.visit "/poltergeist/arbitrary_path/200/foo?a=%20%5B%5D%3A%2F%2B%26%3D"
        expect(request_uri).to eq('/poltergeist/arbitrary_path/200/foo?a=%20%5B%5D%3A%2F%2B%26%3D')
      end
    end

    context 'dragging support' do
      before do
        @session.visit '/poltergeist/drag'
      end

      it 'supports drag_to' do
        draggable = @session.find(:css, '#drag_to #draggable')
        droppable = @session.find(:css, '#drag_to #droppable')

        draggable.drag_to(droppable)
        expect( droppable ).to have_content( "Dropped" )
      end

      it 'supports drag_by on native element' do
        draggable = @session.find(:css, '#drag_by .draggable')

        top_before = @session.evaluate_script('$("#drag_by .draggable").position().top')
        left_before = @session.evaluate_script('$("#drag_by .draggable").position().left')

        draggable.native.drag_by(10, 10)

        top_after = @session.evaluate_script('$("#drag_by .draggable").position().top')
        left_after = @session.evaluate_script('$("#drag_by .draggable").position().left')

        expect( top_after ).to eq( top_before + 10 )
        expect( left_after ).to eq( left_before + 10 )
      end

    end

    context 'window switching support' do
      it 'waits for the window to load' do
        @session.visit '/'

        popup = @session.window_opened_by do
          @session.execute_script <<-JS
            window.open('/poltergeist/slow', 'popup')
          JS
        end

        @session.within_window(popup) do
          expect(@session.html).to include('slow page')
          @session.execute_script('window.close()')
        end
      end

      it 'can access a second window of the same name' do
        @session.visit '/'

        popup = @session.window_opened_by do
          @session.execute_script <<-JS
            window.open('/poltergeist/simple', 'popup')
          JS
        end

        @session.within_window(popup) do
          expect(@session.html).to include('Test')
          @session.execute_script('window.close()')
        end

        another_popup = @session.window_opened_by do
          @session.execute_script <<-JS
            window.open('/poltergeist/simple', 'popup')
          JS
        end

        @session.within_window(another_popup) do
          expect(@session.html).to include('Test')
        end
      end
    end

    context 'frame support' do
      it 'supports selection by index' do
        @session.visit '/poltergeist/frames'

        @session.within_frame 0 do
          expect(@session.current_path).to eq('/poltergeist/slow')
        end
      end

      it 'supports selection by element' do
        @session.visit '/poltergeist/frames'
        frame = @session.find(:css, 'iframe')

        @session.within_frame(frame) do
          expect(@session.current_path).to eq('/poltergeist/slow')
        end
      end

      it 'waits for the frame to load' do
        @session.visit '/'

        @session.execute_script <<-JS
          document.body.innerHTML += '<iframe src="/poltergeist/slow" name="frame">'
        JS

        @session.within_frame 'frame' do
          expect(@session.current_path).to eq('/poltergeist/slow')
          expect(@session.html).to include('slow page')
        end

        expect(@session.current_path).to eq('/')
      end

      it 'waits for the cross-domain frame to load' do
        @session.visit '/poltergeist/frames'
        expect(@session.current_path).to eq('/poltergeist/frames')

        @session.within_frame 'frame' do
          expect(@session.current_path).to eq('/poltergeist/slow')
          expect(@session.body).to include('slow page')
        end

        expect(@session.current_path).to eq('/poltergeist/frames')
      end

      it 'supports clicking in a frame' do
        @session.visit '/'

        @session.execute_script <<-JS
          document.body.innerHTML += '<iframe src="/poltergeist/click_test" name="frame">'
        JS

        @session.within_frame 'frame' do
          log = @session.find(:css, '#log')
          @session.find(:css, '#one').click
          expect(log.text).to eq('one')
        end
      end

      it 'supports clicking in a frame with padding' do
        @session.visit '/'

        @session.execute_script <<-JS
          document.body.innerHTML += '<iframe src="/poltergeist/click_test" name="padded_frame" style="padding:100px;">'
        JS

        @session.within_frame 'padded_frame' do
          log = @session.find(:css, '#log')
          @session.find(:css, '#one').click
          expect(log.text).to eq('one')
        end
      end

      it 'supports clicking in a frame nested in a frame' do
        @session.visit '/'

        # The padding on the frame here is to differ the sizes of the two
        # frames, ensuring that their offsets are being calculated seperately.
        # This avoids a false positive where the same frame's offset is
        # calculated twice, but the click still works because both frames had
        # the same offset.
        @session.execute_script <<-JS
          document.body.innerHTML += '<iframe src="/poltergeist/nested_frame_test" name="outer_frame" style="padding:200px">'
        JS

        @session.within_frame 'outer_frame' do
          @session.within_frame 'inner_frame' do
            log = @session.find(:css, '#log')
            @session.find(:css, '#one').click
            expect(log.text).to eq('one')
          end
        end
      end

      it 'does not wait forever for the frame to load' do
        @session.visit '/'

        expect {
          @session.within_frame('omg') { }
        }.to raise_error(Capybara::Poltergeist::FrameNotFound)
      end
    end

    # see https://github.com/teampoltergeist/poltergeist/issues/115
    it 'handles obsolete node during an attach_file' do
      @session.visit '/poltergeist/attach_file'
      @session.attach_file 'file', __FILE__
    end

    it 'logs mouse event co-ordinates' do
      @session.visit('/')
      @session.find(:css, 'a').click

      position = JSON.load(TestSessions.logger.messages.last)['response']['position']
      expect(position['x']).to_not be_nil
      expect(position['y']).to_not be_nil
    end

    it 'throws an error on an invalid selector' do
      @session.visit '/poltergeist/table'
      expect { @session.find(:css, 'table tr:last') }.to raise_error(Capybara::Poltergeist::InvalidSelector)
    end

    it 'throws an error on wrong xpath' do
      @session.visit('/poltergeist/with_js')
      expect { @session.find(:xpath, '#remove_me') }.to raise_error(Capybara::Poltergeist::InvalidSelector)
    end

    it 'should submit form' do
        @session.visit('/poltergeist/send_keys')
        @session.find(:css, '#without_submit_button').trigger('submit')
        expect(@session.find(:css, '#without_submit_button input').value).to eq('Submitted')
      end

    context 'whitespace stripping tests' do
      before do
        @session.visit '/poltergeist/filter_text_test'
      end

      it 'gets text' do
        expect(@session.find(:css, '#foo').text).to eq 'foo'
      end

      it 'gets text stripped whitespace' do
        expect(@session.find(:css, '#bar').text).to eq 'bar'
      end

      it 'gets text stripped whitespace and nbsp' do
        expect(@session.find(:css, '#baz').text).to eq 'baz'
      end

      it 'gets text stripped whitespace, nbsp and unicode whitespace' do
        expect(@session.find(:css, '#qux').text).to eq 'qux'
      end
    end

    it 'allows access to element attributes' do
      @session.visit '/poltergeist/attributes'
      expect(@session.find(:css,'#my_link').native.attributes).to eq(
        'href' => '#', 'id' => 'my_link', 'class' => 'some_class', 'data' => 'rah!'
      )
    end

    it 'knows about its parents' do
      @session.visit '/poltergeist/simple'
      parents = @session.find(:css, '#nav').native.parents
      expect(parents.map(&:tag_name)).to eq ['li','ul','body','html']
    end

    context 'SVG tests' do
      before do
        @session.visit '/poltergeist/svg_test'
      end

      it 'gets text from tspan node' do
        expect(@session.find(:css, 'tspan').text).to eq 'svg foo'
      end
    end
  end
end
