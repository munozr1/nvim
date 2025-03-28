require('packer').startup(function(use)
	-- Set leader key to <Space>
	vim.api.nvim_set_keymap('', '<Space>', '<Nop>', { noremap = true, silent = true })
	vim.g.mapleader = ' ' -- Set the leader key to Space
	vim.o.wrap = false

	use 'ThePrimeagen/harpoon'
	use 'neovim/nvim-lspconfig'
	use 'wbthomason/packer.nvim'
	use 'EdenEast/nightfox.nvim'
	use 'ribru17/bamboo.nvim'
	-- use {
	--	"github/copilot.vim",
	--	config = function()
			-- Optional: You can configure keybindings or settings here
--			vim.g.copilot_no_tab_map = true
--			vim.api.nvim_set_keymap("i", "<C-J>", 'copilot#Accept("<CR>")', { expr = true, silent = true })
--		end
--	}

	-- use {'morhetz/gruvbox.nvim', config = function() vim.cmd.colorscheme("gruvbox") end }
	use {
		'nvim-telescope/telescope.nvim', tag = '0.1.5',
		-- or                            , branch = '0.1.x',
		requires = { {'nvim-lua/plenary.nvim'} }
	}
	use {
		'hrsh7th/nvim-cmp',
		requires = {
			'hrsh7th/cmp-nvim-lsp',      -- LSP source for nvim-cmp
			'hrsh7th/cmp-buffer',        -- Buffer source
			'hrsh7th/cmp-path',          -- Filesystem path source
			'hrsh7th/cmp-cmdline',       -- Command-line completion
			'L3MON4D3/LuaSnip',          -- Snippet engine
			'saadparwaiz1/cmp_luasnip',  -- Snippet completion source
		}
	}


	--vim.cmd('colorscheme nightfox')
	require('bamboo').load()
	vim.cmd('colorscheme bamboo')
	require('telescope').setup({ 
		defaults = { 
			file_ignore_patterns = { 
				"node_modules" 
			}
		}
	})


	local curse = require("curse")
	vim.api.nvim_create_user_command('CurseQuery',curse.query, {})
	local builtin = require('telescope.builtin')
	require('harpoon').setup({
		tabline = true,
	})
	local hpui = require('harpoon.ui')
	local hpmark = require('harpoon.mark')
	vim.keymap.set('n', '<leader>p', builtin.find_files, {})
	vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
	vim.keymap.set('n', '<leader>fb', builtin.buffers, {})
	vim.keymap.set('n', '<leader>fh', builtin.help_tags, {})
	vim.keymap.set('n', '<leader>funcs', builtin.lsp_document_symbols, {})
	vim.api.nvim_set_keymap('n', '<Leader>j', '<C-w>h', { noremap = true, silent = true })
	vim.api.nvim_set_keymap('n', '<Leader>k', '<C-w>l', { noremap = true, silent = true })
	vim.api.nvim_set_keymap('n', '<S-h>', ':vertical resize +2<CR>', { noremap = false, silent = true })
	vim.api.nvim_set_keymap('n', '<S-l>', ':vertical resize -2<CR>', { noremap = false, silent = true })

	function Nav1()
		hpui.nav_file(1)
	end

	function Nav2()
		hpui.nav_file(2)
	end
	function Nav3()
		hpui.nav_file(3)
	end

	-- harpoon shortcuts
	vim.keymap.set('n', '<leader>hm', hpui.toggle_quick_menu, {})
	vim.keymap.set('n', '<leader>mm', hpmark.add_file, {})
	vim.keymap.set('n', '<leader>1', Nav1, {})
	vim.keymap.set('n', '<leader>2', Nav2, {})
	vim.keymap.set('n', '<leader>3', Nav3, {})
	vim.keymap.set('n', '<leader>hn', hpui.nav_next, {})
	vim.keymap.set('n', '<leader>hp', hpui.nav_prev, {})


	local cmp = require('cmp')

	cmp.setup({
		snippet = {
			expand = function(args)
				require('luasnip').lsp_expand(args.body) -- Use LuaSnip for snippets
			end,
		},
		window = {
			completion = cmp.config.window.bordered(),
			documentation = cmp.config.window.bordered()
		},
		mapping = cmp.mapping.preset.insert({
			['<C-Space>'] = cmp.mapping.complete(),
			['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept suggestion with Enter
			['<Tab>'] = cmp.mapping.select_next_item(),        -- Navigate down
			['<S-Tab>'] = cmp.mapping.select_prev_item(),      -- Navigate up
		}),
		sources = cmp.config.sources({
			{ name = 'nvim_lsp' , max_item_count = 5},
			{ name = 'luasnip' },  -- Snippet support
			{ name = 'buffer' , max_item_count = 2},   -- Text buffer completion
			{ name = 'path' , max_item_count = 2},     -- File system paths
		}),
	})

	local capabilities = require('cmp_nvim_lsp').default_capabilities()
	local lspconfig = require('lspconfig')
	lspconfig.clangd.setup({
		capabilities = capabilities,
		on_attach = function(client, bufnr)
			-- Map "gi" to "Go to Implementation"
			vim.api.nvim_buf_set_keymap(bufnr, 
			'n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>',
			{ noremap = true, silent = true })
		end,
	})
	-- Attach LSP to C/C++ files
	vim.api.nvim_create_autocmd('FileType', {
		pattern = { 'c', 'cpp' },
		callback = function()
			vim.lsp.start({
				name = 'clangd',
				cmd = { 'clangd' }, -- Ensure this points to your clangd executable
				root_dir = vim.fs.dirname(vim.fs.find({ 'compile_commands.json', '.git' }, { upward = true })[1]),
			})
		end,
	})

	lspconfig.lua_ls.setup({
		capabilities = capabilities,
	})

	-- Activate LSPs
	-- All LSPs in this list need to be manually installed via NPM/PNPM/whatevs
	local servers = { 'tailwindcss', 'ts_ls', 'jsonls', 'eslint' }
	for _, lsp in pairs(servers) do
		lspconfig[lsp].setup {
			on_attach = on_attach,
			capabilites = capabilities,
		}
	end

	-- This is an interesting one, for some reason these two LSPs (CSS/HTML) need to
	-- be activated separately outside of the above loop. If someone can tell me why,
	-- send me a note...
	lspconfig.cssls.setup {
		on_attach = on_attach,
		capabilities = capabilities
	}

	lspconfig.html.setup {
		on_attach = on_attach,
		capabilities = capabilities
	}
	lspconfig.ts_ls.setup {
		on_attach = on_attach,
		capabilities = capabilities
	}


end)
